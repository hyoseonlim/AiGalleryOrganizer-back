# app/services/image.py
import uuid
import hashlib
import logging
from datetime import datetime, timezone
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from botocore.exceptions import ClientError
from typing import List

from app.repositories.image import ImageRepository
from app.schemas.image import ImageUploadResponse, PresignedUrl, UploadCompleteResponse, ImageResponse, ImageMetadata
from app.models.user import User
from config.config import settings

logger = logging.getLogger(__name__)

class ImageService:
    def __init__(self, repository: ImageRepository):
        self.repository = repository

    def request_upload_urls(
        self, *, s3_client, image_count: int, user: User
    ) -> ImageUploadResponse:
        if not settings.S3_BUCKET_NAME:
            raise HTTPException(status_code=500, detail="S3 bucket name is not configured.")

        presigned_urls = []
        for _ in range(image_count):
            object_key = f"images/{user.id}/{uuid.uuid4()}.jpg"
            
            new_image = self.repository.create(user_id=user.id, url=object_key, is_saved=False)

            try:
                url = s3_client.generate_presigned_url(
                    'put_object',
                    Params={'Bucket': settings.S3_BUCKET_NAME, 'Key': object_key},
                    ExpiresIn=3600
                )
                presigned_urls.append(PresignedUrl(image_id=new_image.id, presigned_url=url))
            except ClientError as e:
                logger.error(f"Error generating presigned URL: {e}")
                self.repository.delete_permanently(new_image)
                raise HTTPException(status_code=500, detail="Could not generate upload URL.")

        return ImageUploadResponse(presigned_urls=presigned_urls)

    def notify_upload_complete(
        self, *, image_id: int, hash: str, metadata: ImageMetadata, user: User
    ) -> UploadCompleteResponse:
        image = self.repository.find_by_id(image_id, user.id)

        if not image:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Image not found.")
        if image.is_saved:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Image already processed.")

        try:
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

            return UploadCompleteResponse(
                image_id=updated_image.id,
                status="completed",
                hash=updated_image.hash
            )
        except Exception as e:
            logger.error(f"An error occurred: {e}")
            raise HTTPException(status_code=500, detail="An internal error occurred.")

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
            # Decide if you want to proceed with DB deletion even if S3 fails
            # For now, we'll raise an error and stop.
            raise HTTPException(status_code=500, detail="Could not delete image from cloud storage.")

        self.repository.delete_permanently(image)

    def get_all_images_by_user(self, *, user: User) -> List[ImageResponse]:
        images = self.repository.find_all_by_user(user.id)
        return [ImageResponse.from_orm(img) for img in images]
