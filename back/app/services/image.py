# app/services/image.py
import uuid
import logging
import json
from datetime import datetime, timezone
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from botocore.exceptions import ClientError
from typing import List, Optional

from app.repositories.image import ImageRepository
from app.schemas.image import (
    ImageUploadRequest, 
    ImageUploadResponse, 
    UploadInstruction, 
    DuplicateInfo, 
    ImageResponse, 
    ImageMetadata
)
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
        self, *, s3_client, images_data: ImageUploadRequest, user: User
    ) -> ImageUploadResponse:
        if not settings.S3_BUCKET_NAME:
            raise HTTPException(status_code=500, detail="S3 bucket name is not configured.")

        uploads = []
        duplicates = []

        try:
            for img_data in images_data.images:
                existing_image = self.repository.find_by_hash(img_data.hash)
                if existing_image:
                    duplicates.append(DuplicateInfo(
                        client_id=img_data.client_id,
                        existing_image_id=existing_image.id
                    ))
                else:
                    object_key = f"images/{user.id}/{uuid.uuid4()}.jpg"
                    new_image = self.repository.create(user_id=user.id, url=object_key, hash=img_data.hash, is_saved=False)
                    
                    url = s3_client.generate_presigned_url(
                        'put_object',
                        Params={'Bucket': settings.S3_BUCKET_NAME, 'Key': object_key},
                        ExpiresIn=3600
                    )
                    uploads.append(UploadInstruction(
                        client_id=img_data.client_id,
                        image_id=new_image.id,
                        presigned_url=url
                    ))
            self.repository.db.commit()
        except ClientError as e:
            logger.error(f"Error generating presigned URL: {e}")
            self.repository.db.rollback()
            raise HTTPException(status_code=500, detail="Could not generate upload URL.")

        return ImageUploadResponse(uploads=uploads, duplicates=duplicates)

    def notify_upload_complete(
        self, *, image_id: int, metadata: ImageMetadata, user: User
    ) -> Image:
        image = self.repository.find_by_id(image_id, user.id)

        if not image:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Image not found.")
        if image.is_saved:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Image already processed.")

        update_data = {
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
        tag_name: str,
        tag_category: Optional[str],
        tag_probability: float,
        score: Optional[float],
        ai_embedding: Optional[List[float]],
    ) -> Image:
        """
        AI 분석 결과를 이미지에 저장합니다.

        Args:
            image_id: 이미지 ID
            tag_name: AI가 예측한 태그 이름
            tag_category: AI가 예측한 카테고리
            tag_probability: 태그 예측 확률 (%)
            score: 이미지 품질 점수 (0-1)
            ai_embedding: 이미지 feature vector
        """
        # 파라미터로 받은 db 세션 사용 (중요!)
        image = db.query(Image).filter(Image.id == image_id).first()
        if not image:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Image not found.")

        # TODO: 임계값 정의 및 적용
        # - tag_probability가 임계값 이상일 때만 태그 저장
        # - category_probability가 임계값 이상일 때만 카테고리 연결
        # 예: TAG_CONFIDENCE_THRESHOLD = 30.0 (%)

        # Handle Category and Tag
        if tag_category:
            from app.models.category import Category
            from app.models.tag import Tag
            from app.models.association import ImageTag

            # Category 찾기 또는 생성 (같은 db 세션 사용)
            category = db.query(Category).filter(Category.name == tag_category).first()
            if not category:
                category = Category(name=tag_category)
                db.add(category)
                db.flush()  # ID 할당을 위해 flush

            # Tag 찾기 또는 생성 (같은 db 세션 사용)
            tag_obj = db.query(Tag).filter(
                Tag.name == tag_name,
                Tag.category_id == category.id
            ).first()
            if not tag_obj:
                tag_obj = Tag(name=tag_name, category_id=category.id)
                db.add(tag_obj)
                db.flush()  # ID 할당을 위해 flush

            # ImageTag에 태그 추가 (confidence 포함)
            existing_image_tag = db.query(ImageTag).filter_by(
                image_id=image.id,
                tag_id=tag_obj.id
            ).first()

            if not existing_image_tag:
                image_tag = ImageTag(
                    image_id=image.id,
                    tag_id=tag_obj.id,
                    confidence=tag_probability / 100.0  # 백분율을 0-1 범위로 변환
                )
                db.add(image_tag)

        # Update Image (같은 db 세션 사용)
        if ai_embedding is not None:
            # JSON 형식으로 저장하여 일관성 유지
            image.ai_embedding = json.dumps(ai_embedding)
        if score is not None:
            image.score = score
        image.ai_processing_status = AIProcessingStatus.COMPLETED

        db.commit()
        db.refresh(image)
        return image

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
