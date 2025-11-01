# app/routers/images.py
from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.orm import Session
from typing import List

from app.dependencies import get_db, get_image_service, get_current_user
from app.aws import get_s3_client
from app.schemas.image import (
    ImageUploadRequest,
    ImageUploadResponse,
    UploadCompleteRequest,
    UploadCompleteResponse,
    ImageViewableResponse,
    ImageResponse,
    ImageAnalysisResult,
    ImageDetailResponse,
)
from app.schemas.tag import ImageTagRequest, TagResponse
from app.models.user import User
from app.services.image import ImageService
from app.celery_worker import celery_app
from config.config import settings

router = APIRouter(tags=["images"])

@router.post("/upload/request", response_model=ImageUploadResponse)
def request_upload_urls(
    request: ImageUploadRequest,
    s3_client=Depends(get_s3_client),
    image_service: ImageService = Depends(get_image_service),
    current_user: User = Depends(get_current_user),
):
    """
    여러 이미지 업로드를 위한 사전 서명된 URL을 생성합니다.
    요청 전에 해시를 비교하여 중복된 이미지는 제외합니다.
    """
    return image_service.request_upload_urls(
        s3_client=s3_client,
        images_data=request,
        user=current_user
    )


@router.post("/upload/complete", response_model=UploadCompleteResponse)
def notify_upload_complete(
    request: UploadCompleteRequest,
    image_service: ImageService = Depends(get_image_service),
    current_user: User = Depends(get_current_user),
):
    """
    이미지 업로드가 완료되었음을 서버에 알리고 처리를 시작합니다.
    """
    updated_image = image_service.notify_upload_complete(
        image_id=request.image_id,
        metadata=request.metadata,
        user=current_user
    )

    if settings.CLOUDFRONT_DOMAIN:
        full_image_url = f"https://{settings.CLOUDFRONT_DOMAIN}/{updated_image.url}"
        # AI 서버의 Celery worker에게 분석 작업 전송
        celery_app.send_task(
            'app.tasks.analyze_image_task',
            kwargs={
                'image_url': full_image_url,
                'image_id': updated_image.id
            }
        )
    else:
        # Handle case where CloudFront is not configured, perhaps log a warning
        print("CloudFront domain is not configured, skipping AI analysis task.")

    return UploadCompleteResponse(
        image_id=updated_image.id,
        status="completed",
        hash=updated_image.hash
    )


@router.get("/", response_model=List[ImageResponse])
def get_all_images(
    skip: int = 0,
    limit: int = 100,
    image_service: ImageService = Depends(get_image_service),
    current_user: User = Depends(get_current_user),
):
    """
    현재 사용자의 모든 이미지를 페이지네이션하여 가져옵니다.
    """
    return image_service.get_all_images_by_user(user=current_user, skip=skip, limit=limit)


@router.get("/{image_id}/detail", response_model=ImageDetailResponse)
def get_image_detail(
    image_id: int,
    image_service: ImageService = Depends(get_image_service),
    current_user: User = Depends(get_current_user),
):
    """
    이미지 상세 정보를 조회합니다 (태그, 카테고리, EXIF 정보 포함).
    """
    return image_service.get_image_detail(image_id=image_id, user_id=current_user.id)


@router.get("/{image_id}/view", response_model=ImageViewableResponse)
def get_viewable_image_url(
    image_id: int,
    image_service: ImageService = Depends(get_image_service),
    current_user: User = Depends(get_current_user),
):
    """
    완료된 이미지에 대한 공개적으로 볼 수 있는 URL을 가져옵니다.
    URL은 CloudFront를 통해 제공됩니다.
    """
    url = image_service.get_viewable_url(image_id=image_id, user=current_user)
    return ImageViewableResponse(image_id=image_id, url=url)

@router.get("/{image_id}/tags", response_model=List[TagResponse])
def get_image_tags(
    image_id: int,
    image_service: ImageService = Depends(get_image_service),
    current_user: User = Depends(get_current_user),
):
    """
    이미지에 달린 모든 태그를 조회합니다.
    """
    return image_service.get_tags_for_image(image_id, current_user.id)


@router.post("/{image_id}/tags", status_code=status.HTTP_204_NO_CONTENT)
def add_tags_to_image(
    image_id: int,
    request: ImageTagRequest,
    image_service: ImageService = Depends(get_image_service),
    current_user: User = Depends(get_current_user),
):
    """
    이미지에 태그를 추가합니다. 태그가 없으면 'custom' 카테고리로 새로 생성합니다.
    """
    image_service.add_tags_to_image(image_id, current_user.id, request.tag_names)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.delete("/{image_id}/tags", status_code=status.HTTP_204_NO_CONTENT)
def remove_tags_from_image(
    image_id: int,
    request: ImageTagRequest,
    image_service: ImageService = Depends(get_image_service),
    current_user: User = Depends(get_current_user),
):
    """
    이미지에서 태그를 제거합니다.
    """
    image_service.remove_tags_from_image(image_id, current_user.id, request.tag_names)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.delete("/{image_id}", status_code=status.HTTP_204_NO_CONTENT)
def soft_delete_image(
    image_id: int,
    image_service: ImageService = Depends(get_image_service),
    current_user: User = Depends(get_current_user),
):
    """
    이미지를 휴지통으로 이동합니다 (소프트 삭제).
    """
    image_service.soft_delete_image(image_id=image_id, user=current_user)
    return Response(status_code=status.HTTP_204_NO_CONTENT)

@router.get("/trash", response_model=List[ImageResponse])
def get_trashed_images(
    image_service: ImageService = Depends(get_image_service),
    current_user: User = Depends(get_current_user),
):
    """
    현재 사용자의 모든 휴지통 이미지를 가져옵니다.
    """
    return image_service.get_trashed_images(user=current_user)

@router.post("/{image_id}/restore", response_model=ImageResponse)
def restore_image(
    image_id: int,
    image_service: ImageService = Depends(get_image_service),
    current_user: User = Depends(get_current_user),
):
    """
    휴지통에서 이미지를 복원합니다.
    """
    return image_service.restore_image(image_id=image_id, user=current_user)

@router.post("/{image_id}/analysis-results", status_code=status.HTTP_200_OK)
def receive_analysis_results(
    image_id: int,
    results: ImageAnalysisResult,
    image_service: ImageService = Depends(get_image_service),
    db: Session = Depends(get_db),
):
    """
    AI 서버로부터 태그, 카테고리, 임베딩 등 AI 분석 결과를 받아 데이터베이스의 이미지 정보를 업데이트합니다.
    """
    image_service.update_image_analysis_results(
        db=db,
        image_id=image_id,
        tag_name=results.tag_name,
        tag_category=results.category,
        tag_probability=results.probability,
        score=results.quality_score,
        ai_embedding=results.feature_vector,
    )
    return {"message": "Analysis results received and processed successfully."}

@router.delete("/trash/{image_id}", status_code=status.HTTP_204_NO_CONTENT)
def permanently_delete_image(
    image_id: int,
    s3_client=Depends(get_s3_client),
    image_service: ImageService = Depends(get_image_service),
    current_user: User = Depends(get_current_user),
):
    """
    휴지통과 S3에서 이미지를 영구적으로 삭제합니다.
    """
    image_service.permanently_delete_image(s3_client=s3_client, image_id=image_id, user=current_user)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
