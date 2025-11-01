from fastapi import APIRouter, Depends, status
from typing import List

from app.dependencies import get_current_user, get_tag_service
from app.models.user import User
from app.schemas.tag import TagCreate, TagUpdate, TagResponse
from app.services.tag import TagService

router = APIRouter(tags=["tags"])

@router.post(
    "/",
    response_model=TagResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_tag(
    tag_data: TagCreate,
    service: TagService = Depends(get_tag_service),
    current_user: User = Depends(get_current_user),
):
    """새 태그를 생성합니다."""
    return service.create_tag(tag_data, user_id=current_user.id)

@router.get(
    "/",
    response_model=List[TagResponse],
)
def get_all_tags(
    skip: int = 0,
    limit: int = 100,
    service: TagService = Depends(get_tag_service),
    current_user: User=Depends(get_current_user),
):
    """현재 사용자가 볼 수 있는 모든 태그 목록을 가져옵니다."""
    return service.get_tags(user_id=current_user.id, skip=skip, limit=limit)

@router.get(
    "/{tag_id}",
    response_model=TagResponse,
)
def get_tag_by_id(
    tag_id: int,
    service: TagService = Depends(get_tag_service),
    current_user: User=Depends(get_current_user),
):
    """ID로 단일 태그를 가져옵니다."""
    return service.get_tag(tag_id)

@router.put(
    "/{tag_id}",
    response_model=TagResponse,
    status_code=status.HTTP_200_OK,
)
def update_tag(
    tag_id: int,
    tag_data: TagUpdate,
    service: TagService = Depends(get_tag_service),
    current_user: User = Depends(get_current_user),
):
    """기존 태그를 업데이트합니다."""
    return service.update_tag(tag_id, tag_data)

@router.delete("/{tag_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_tag(
    tag_id: int,
    service: TagService = Depends(get_tag_service),
    current_user: User = Depends(get_current_user),
):
    """태그를 삭제합니다."""
    service.delete_tag(tag_id)