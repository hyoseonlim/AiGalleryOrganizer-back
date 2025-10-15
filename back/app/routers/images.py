# app/routers/images.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.dependencies import get_db
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

router = APIRouter(
    tags=["images"],
)

@router.post("/upload/request", response_model=ImageUploadResponse)
def request_upload_urls(
    request: ImageUploadRequest,
    db: Session = Depends(get_db),
    s3_client = Depends(get_s3_client),
    # current_user: User = Depends(get_current_user), # TEMPORARILY DISABLED
):
    """
    Generate presigned URLs for uploading a number of images.
    """
    # TODO JWT 인증 구현 후 ==1로 픽스해둔 거 고치기. (이때 docker-compose.yml에 secret key도 처리 필요)
    current_user = db.query(User).filter(User.id == 1).first()

    service = ImageService(db)
    return service.request_upload_urls(
        s3_client=s3_client, 
        image_count=request.image_count, 
        user=current_user
    )


@router.post("/upload/complete", response_model=UploadCompleteResponse)
def notify_upload_complete(
    request: UploadCompleteRequest,
    db: Session = Depends(get_db),
    s3_client = Depends(get_s3_client),
    # current_user: User = Depends(get_current_user), # TEMPORARILY DISABLED
):
    """
    Notify the server that an image upload is complete and trigger processing.
    """
    # --- TEMPORARY FIX for testing without authentication ---
    # This should be replaced by a real authentication system.
    # In a real scenario, the user would be retrieved from a dependency.
    temp_user = db.query(User).filter(User.id == 1).first()
    if not temp_user:
        # This part is unlikely to be hit if the first endpoint was called, but for safety:
        temp_user = User(id=1, email="testuser@example.com", password="a-dummy-password")
        db.add(temp_user)
        db.commit()
        db.refresh(temp_user)
    current_user = temp_user
    # --- END OF TEMPORARY FIX ---

    service = ImageService(db)
    return service.notify_upload_complete(
        s3_client=s3_client, 
        image_id=request.image_id, 
        user=current_user
    )
