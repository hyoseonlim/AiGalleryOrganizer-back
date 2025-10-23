# app/routers/images.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.dependencies import get_db, get_image_service, get_user_service
from app.aws import get_s3_client
from app.schemas.image import (
    ImageUploadRequest,
    ImageUploadResponse,
    UploadCompleteRequest,
    UploadCompleteResponse,
)
from app.models.user import User
# from app.security import get_current_user # TEMPORARILY DISABLED
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
    user_service: UserService = Depends(get_user_service),
    # current_user: User = Depends(get_current_user), # TEMPORARILY DISABLED
):
    """
    Generate presigned URLs for uploading a number of images.
    """
    # TODO JWT 인증 구현 후 ==1로 픽스해둔 거 고치기. (이때 docker-compose.yml에 secret key도 처리 필요)
    current_user = user_service.get_user(1)

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
    user_service: UserService = Depends(get_user_service),
    # current_user: User = Depends(get_current_user), # TEMPORARILY DISABLED
):
    """
    Notify the server that an image upload is complete and trigger processing.
    """
    # TODO JWT 인증 구현 후 ==1로 픽스해둔 거 고치기. (이때 docker-compose.yml에 secret key도 처리 필요)
    current_user = user_service.get_user(1)

    return image_service.notify_upload_complete(
        s3_client=s3_client,
        image_id=request.image_id,
        user=current_user
    )
