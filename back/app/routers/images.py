# app/routers/images.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.dependencies import get_db, get_image_service, get_user_service, get_current_user
from app.aws import get_s3_client
from app.schemas.image import (
    ImageUploadRequest,
    ImageUploadResponse,
    UploadCompleteRequest,
    UploadCompleteResponse,
)
from app.models.user import User
from app.services.image import ImageService
from app.services.user import UserService

router = APIRouter(
    tags=["images"],
)

@router.post("/upload/request", response_model=ImageUploadResponse)
def request_upload_urls(
    request: ImageUploadRequest,
    s3_client=Depends(get_s3_client),
    image_service: ImageService = Depends(get_image_service),
    current_user: User = Depends(get_current_user),
):
    """
    Generate presigned URLs for uploading a number of images.
    """
    return image_service.request_upload_urls(
        s3_client=s3_client,
        image_count=request.image_count,
        user=current_user
    )


@router.post("/upload/complete", response_model=UploadCompleteResponse)
def notify_upload_complete(
    request: UploadCompleteRequest,
    s3_client=Depends(get_s3_client),
    image_service: ImageService = Depends(get_image_service),
    current_user: User = Depends(get_current_user),
):
    """
    Notify the server that an image upload is complete and trigger processing.
    """
    return image_service.notify_upload_complete(
        s3_client=s3_client,
        image_id=request.image_id,
        user=current_user
    )
