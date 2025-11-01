# app/services/image.py
import uuid
import logging
from datetime import datetime, timezone
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from botocore.exceptions import ClientError
from typing import List

from app.repositories.image import ImageRepository
from app.schemas.image import ImageUploadResponse, PresignedUrl, ImageResponse, ImageMetadata
from app.models.user import User
from app.models.image import Image, AIProcessingStatus
from app.repositories.category import CategoryRepository
from app.repositories.tag import TagRepository
from config.config import settings

from app.models.tag import Tag

logger = logging.getLogger(__name__)

class ImageService:
    def __init__(self, repository: ImageRepository, category_repository: CategoryRepository, tag_repository: TagRepository):
        self.repository = repository
        self.category_repository = category_repository
        self.tag_repository = tag_repository

    def request_upload_urls(
        self, *, s3_client, image_count: int, user: User
    ) -> ImageUploadResponse:
        if not settings.S3_BUCKET_NAME:
            raise HTTPException(status_code=500, detail="S3 bucket name is not configured.")

        presigned_urls = []
        try:
            for _ in range(image_count):
                object_key = f"images/{user.id}/{uuid.uuid4()}.jpg"
                
                new_image = self.repository.create(user_id=user.id, url=object_key, is_saved=False)

                url = s3_client.generate_presigned_url(
                    'put_object',
                    Params={'Bucket': settings.S3_BUCKET_NAME, 'Key': object_key},
                    ExpiresIn=3600
                )
                presigned_urls.append(PresignedUrl(image_id=new_image.id, presigned_url=url))
            self.repository.db.commit()
        except ClientError as e:
            logger.error(f"Error generating presigned URL: {e}")
            self.repository.db.rollback()
            raise HTTPException(status_code=500, detail="Could not generate upload URL.")

        return ImageUploadResponse(presigned_urls=presigned_urls)

    def notify_upload_complete(
        self, *, image_id: int, hash: str, metadata: ImageMetadata, user: User
    ) -> Image:
        image = self.repository.find_by_id(image_id, user.id)

        if not image:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Image not found.")
        if image.is_saved:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Image already processed.")

        existing_image = self.repository.find_by_hash(hash)
        if existing_image:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=f"Identical image already exists (ID: {existing_image.id}).")

        update_data = {
            "hash": hash,
            "size": metadata.file_size,
            "is_saved": True,
            "exif": metadata.model_dump()
        }
        updated_image = self.repository.update(image, **update_data)
        self.repository.db.commit()
        self.repository.db.refresh(updated_image)
        return updated_image

    def get_viewable_url(self, *, image_id: int, user: User) -> str:
        if not settings.CLOUDFRONT_DOMAIN:
            raise HTTPException(
                status_code=status.HTTP_501_NOT_IMPLEMENTED,
                detail="CloudFront domain is not configured."
            )

        image = self.repository.find_by_id(image_id, user.id)

        if not image:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Image not found.")

        if not image.is_saved:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Image processing is not complete.")

        return f"https://{settings.CLOUDFRONT_DOMAIN}/{image.url}"

    def soft_delete_image(self, *, image_id: int, user: User) -> None:
        image = self.repository.find_by_id(image_id, user.id)
        if not image:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Image not found.")
        
        self.repository.update(image, deleted_at=datetime.now(timezone.utc))
        self.repository.db.commit()

    def get_trashed_images(self, *, user: User) -> List[ImageResponse]:
        images = self.repository.find_trashed_by_user(user.id)
        return [ImageResponse.from_orm(img) for img in images]

    def restore_image(self, *, image_id: int, user: User) -> ImageResponse:
        image = self.repository.find_by_id_including_trashed(image_id, user.id)
        if not image:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Image not found.")
        if image.deleted_at is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Image is not in trash.")

        self.repository.update(image, deleted_at=None)
        self.repository.db.commit()
        self.repository.db.refresh(image)
        return ImageResponse.from_orm(image)

    def permanently_delete_image(self, *, s3_client, image_id: int, user: User) -> None:
        image = self.repository.find_by_id_including_trashed(image_id, user.id)
        if not image:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Image not found.")
        
        if image.deleted_at is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Image is not in trash. Soft delete it first.")

        try:
            s3_client.delete_object(Bucket=settings.S3_BUCKET_NAME, Key=image.url)
        except ClientError as e:
            logger.error(f"Error deleting image from S3: {e}")
            raise HTTPException(status_code=500, detail="Could not delete image from cloud storage.")

        self.repository.delete_permanently(image)
        self.repository.db.commit()

    def get_all_images_by_user(self, *, user: User, skip: int = 0, limit: int = 100) -> List[ImageResponse]:
        images = self.repository.find_all_by_user(user.id, skip=skip, limit=limit)
        return [ImageResponse.from_orm(img) for img in images]

    def update_image_analysis_results(
        self,
        db: Session,
        image_id: int,
        tag: str,
        tag_category: str,
        score: float,
        ai_embedding: List[float],
    ) -> Image:
        image = self.repository.find_by_id_for_analysis(image_id)
        if not image:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Image not found.")

        # Handle Category
        category = self.category_repository.find_by_name(tag_category)
        if not category:
            from app.schemas.category import CategoryCreate # Import locally to avoid circular dependency
            category_create_schema = CategoryCreate(name=tag_category)
            category = self.category_repository.create(category_create_schema)

        # Handle Tag
        tag_obj = self.tag_repository.find_by_name_and_category_id(tag, category.id)
        if not tag_obj:
            from app.schemas.tag import TagCreate # Import locally to avoid circular dependency
            tag_create_schema = TagCreate(name=tag, category_id=category.id)
            tag_obj = self.tag_repository.create(tag_create_schema)

        # Update Image
        updated_image = self.repository.update(
            image,
            ai_embedding=ai_embedding,
            score=score,
            tag_id=tag_obj.id,
            ai_processing_status=AIProcessingStatus.COMPLETED
        )
        self.repository.db.commit()
        self.repository.db.refresh(updated_image)
        return updated_image

    def add_tags_to_image(self, image_id: int, user_id: int, tag_names: List[str]):
        image = self.repository.find_by_id(image_id, user_id)
        if not image:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Image not found.")

        custom_category = self.category_repository.find_by_name("custom")
        if not custom_category:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Custom category not found.")

        tags = self.tag_repository.find_or_create_tags_by_name(user_id, tag_names, custom_category.id)
        self.repository.add_tags_to_image(image, tags)
        self.repository.db.commit()

    def remove_tags_from_image(self, image_id: int, user_id: int, tag_names: List[str]):
        image = self.repository.find_by_id(image_id, user_id)
        if not image:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Image not found.")

        tags = [self.tag_repository.find_by_name(name) for name in tag_names if self.tag_repository.find_by_name(name)]
        if not tags:
            return
            
        self.repository.remove_tags_from_image(image, tags)
        self.repository.db.commit()
