# app/services/image.py
import uuid
import hashlib
import logging
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from botocore.exceptions import ClientError

from app.repositories.image import ImageRepository
from app.schemas.image import ImageUploadResponse, PresignedUrl, UploadCompleteResponse
from app.models.user import User
from config.config import settings

logger = logging.getLogger(__name__)

class ImageService:
    def __init__(self, repository: ImageRepository):
        self.repository = repository

    def request_upload_urls(
        self, *, s3_client, image_count: int, user: User
    ) -> ImageUploadResponse:
        if not settings.S3_BUCKET_NAME in settings.S3_BUCKET_NAME:
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
                self.repository.delete(new_image)
                raise HTTPException(status_code=500, detail="Could not generate upload URL.")

        return ImageUploadResponse(presigned_urls=presigned_urls)

    def notify_upload_complete(
        self, *, s3_client, image_id: int, user: User
    ) -> UploadCompleteResponse:
        image = self.repository.find_by_id(image_id)

        if not image:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Image not found.")
        if image.user_id != user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="User not authorized.")
        if image.is_saved:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Image already processed.")

        try:
            s3_object = s3_client.get_object(Bucket=settings.S3_BUCKET_NAME, Key=image.url)
            image_data = s3_object['Body'].read()
            
            image_hash = hashlib.sha256(image_data).hexdigest()
            image_size = len(image_data)

            existing_image = self.repository.find_by_hash(image_hash)
            if existing_image:
                raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=f"Identical image already exists (ID: {existing_image.id}).")

            updated_image = self.repository.update(image, hash=image_hash, size=image_size, is_saved=True)

            return UploadCompleteResponse(
                image_id=updated_image.id,
                status="completed",
                hash=updated_image.hash
            )
        except ClientError as e:
            logger.error(f"Error from S3: {e}")
            raise HTTPException(status_code=404, detail="File not found in S3. Upload may have failed.")
        except Exception as e:
            logger.error(f"An error occurred: {e}")
            raise HTTPException(status_code=500, detail="An internal error occurred.")

    def get_viewable_url(self, *, image_id: int, user: User) -> str:
        if not settings.CLOUDFRONT_DOMAIN:
            raise HTTPException(
                status_code=status.HTTP_501_NOT_IMPLEMENTED,
                detail="CloudFront domain is not configured."
            )

        image = self.repository.find_by_id(image_id)

        if not image:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Image not found.")
        if image.user_id != user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="User not authorized.")

        if not image.is_saved:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Image processing is not complete.")

        return f"https://{settings.CLOUDFRONT_DOMAIN}/{image.url}"
