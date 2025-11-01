from fastapi import HTTPException, status
from typing import List, Optional

from app.models.tag import Tag
from app.repositories.tag import TagRepository
from app.repositories.category import CategoryRepository
from app.schemas.tag import TagCreate, TagUpdate, TagResponse

class TagService:
    def __init__(self, repository: TagRepository, category_repository: CategoryRepository):
        self.repository = repository
        self.category_repository = category_repository

    def get_tag(self, tag_id: int) -> Tag:
        tag = self.repository.find_by_id(tag_id)
        if not tag:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Tag with id {tag_id} not found",
            )
        return tag

    def get_tags(self, user_id: int, skip: int = 0, limit: int = 100) -> List[TagResponse]:
        tags = self.repository.find_tags_for_user(user_id=user_id, skip=skip, limit=limit)
        return [TagResponse.model_validate(tag) for tag in tags]

    def create_tag(self, tag_data: TagCreate, user_id: Optional[int] = None) -> TagResponse:
        # 카테고리 ID 유효성 검사
        category = self.category_repository.find_by_id(tag_data.category_id)
        if not category:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Category with id {tag_data.category_id} not found",
            )

        # 같은 이름의 태그가 이미 존재하는지 확인
        existing_tag = self.repository.find_by_name(tag_data.name)
        if existing_tag:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT, # 409 Conflict - 리소스가 이미 존재함
                detail=f"Tag with name '{tag_data.name}' already exists",
            )

        tag = self.repository.create(tag_data, user_id)
        return TagResponse.model_validate(tag)
    
    def update_tag(self, tag_id: int, tag_data: TagUpdate) -> TagResponse: # 반환 타입 변경됨
        tag = self.repository.find_by_id(tag_id)
        if not tag:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Tag with id {tag_id} not found"
            )

        # 카테고리 ID가 업데이트되는 경우 유효성 검사
        if tag_data.category_id is not None and tag_data.category_id != tag.category_id:
            category = self.category_repository.find_by_id(tag_data.category_id)
            if not category:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Category with id {tag_data.category_id} not found",
                )

        # 이름이 업데이트되는 경우 이름 충돌 확인
        if tag_data.name and tag_data.name != tag.name:
            existing_tag = self.repository.find_by_name(tag_data.name)
            if existing_tag and existing_tag.id != tag_id:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=f"Tag with name '{tag_data.name}' already exists",
                )

        updated_tag = self.repository.update(tag, tag_data)
        return TagResponse.model_validate(updated_tag)
    
    def delete_tag(self, tag_id: int) -> None:
        tag = self.repository.find_by_id(tag_id)
        if not tag:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Tag with id {tag_id} not found"
            )

        self.repository.delete(tag)