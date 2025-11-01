# back/app/routers/similar_group.py
from fastapi import APIRouter, Depends
from typing import List
from app.dependencies import get_current_user, get_similar_group_service
from app.models.user import User
from app.services.similar_group_service import SimilarGroupService
from app.schemas.similar_group import SimilarGroupResponse
from app.schemas.image import ImageResponse

router = APIRouter(tags=["similar-groups"])

@router.post("/", response_model=List[SimilarGroupResponse])
def find_and_group_images(
    eps: float = 0.15,
    min_samples: int = 2,
    service: SimilarGroupService = Depends(get_similar_group_service),
    current_user: User = Depends(get_current_user),
):
    """
    사용자의 이미지를 기반으로 유사한 사진 그룹을 찾아 생성하고, 그 결과를 반환합니다.
    """
    created_groups = service.create_similar_groups(
        user_id=current_user.id, 
        eps=eps, 
        min_samples=min_samples
    )
    return created_groups

@router.get("/{group_id}/images", response_model=List[ImageResponse])
def get_images_for_group(
    group_id: int,
    service: SimilarGroupService = Depends(get_similar_group_service),
    current_user: User = Depends(get_current_user),
):
    """
    특정 유사 그룹에 속한 이미지 목록을 반환합니다.
    """
    images = service.get_images_for_group(group_id, current_user.id)
    return images
