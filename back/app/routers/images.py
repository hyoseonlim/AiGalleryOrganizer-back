# app/routers/images.py
from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.orm import Session
from typing import List

from app.dependencies import get_db, get_image_service, get_user_service, get_current_user
from app.aws import get_s3_client
from app.schemas.image import (
    ImageUploadRequest,
    ImageUploadResponse,
    UploadCompleteRequest,
    UploadCompleteResponse,
    ImageViewableResponse,
    ImageResponse,
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


@router.get("/{image_id}/view", response_model=ImageViewableResponse)
def get_viewable_image_url(
    image_id: int,
    image_service: ImageService = Depends(get_image_service),
    current_user: User = Depends(get_current_user),
):
    """
    Get a publicly viewable URL for a completed image.
    The URL is served via CloudFront.
    """
    url = image_service.get_viewable_url(image_id=image_id, user=current_user)
    return ImageViewableResponse(image_id=image_id, url=url)

@router.delete("/{image_id}", status_code=status.HTTP_204_NO_CONTENT)
def soft_delete_image(
    image_id: int,
    image_service: ImageService = Depends(get_image_service),
    current_user: User = Depends(get_current_user),
):
    """
    Soft delete an image. The image will be moved to trash.
    """
    image_service.soft_delete_image(image_id=image_id, user=current_user)
    return Response(status_code=status.HTTP_204_NO_CONTENT)

@router.get("/trash", response_model=List[ImageResponse])
def get_trashed_images(
    image_service: ImageService = Depends(get_image_service),
    current_user: User = Depends(get_current_user),
):
    """
    Get all soft-deleted images for the current user.
    """
    return image_service.get_trashed_images(user=current_user)

@router.post("/{image_id}/restore", response_model=ImageResponse)
def restore_image(
    image_id: int,
    image_service: ImageService = Depends(get_image_service),
    current_user: User = Depends(get_current_user),
):
    """
    Restore a soft-deleted image from trash.
    """
    return image_service.restore_image(image_id=image_id, user=current_user)

@router.delete("/trash/{image_id}", status_code=status.HTTP_204_NO_CONTENT)
def permanently_delete_image(
    image_id: int,
    s3_client=Depends(get_s3_client),
    image_service: ImageService = Depends(get_image_service),
    current_user: User = Depends(get_current_user),
):
    """
    Permanently delete an image from trash and S3.
    """
    image_service.permanently_delete_image(s3_client=s3_client, image_id=image_id, user=current_user)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
