from fastapi import HTTPException, status
from typing import List, Optional

from app.models.tag import Tag
from app.repositories.tag import TagRepository
from app.repositories.category import CategoryRepository # Import CategoryRepository
from app.schemas.tag import TagCreate, TagUpdate, TagResponse # Removed TagBaseResponse
# from app.models.tag import TagCategory # Removed

class TagService:
    def __init__(self, repository: TagRepository, category_repository: CategoryRepository):
        self.repository = repository
        self.category_repository = category_repository # Added

    def get_tag(self, tag_id: int) -> Tag: # This still returns the ORM Tag object
        tag = self.repository.find_by_id(tag_id)
        if not tag:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Tag with id {tag_id} not found",
            )
        return tag

    def get_tags(self, user_id: int, skip: int = 0, limit: int = 100) -> List[TagResponse]:
        tags = self.repository.find_tags_for_user(user_id=user_id, skip=skip, limit=limit) # Changed method call
        return [TagResponse.model_validate(tag) for tag in tags]

    def create_tag(self, tag_data: TagCreate, user_id: Optional[int] = None) -> TagResponse: # Changed return type
        # Validate category_id
        category = self.category_repository.find_by_id(tag_data.category_id)
        if not category:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Category with id {tag_data.category_id} not found",
            )
        
        # Check if a tag with the same name already exists
        existing_tag = self.repository.find_by_name(tag_data.name)
        if existing_tag:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT, # 409 Conflict for resource already exists
                detail=f"Tag with name '{tag_data.name}' already exists",
            )

        tag = self.repository.create(tag_data, user_id)
        return TagResponse.model_validate(tag)
    
    def update_tag(self, tag_id: int, tag_data: TagUpdate) -> TagResponse: # Changed return type
        tag = self.repository.find_by_id(tag_id)
        if not tag:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Tag with id {tag_id} not found"
            )
        
        # Validate category_id if it's being updated
        if tag_data.category_id is not None and tag_data.category_id != tag.category_id:
            category = self.category_repository.find_by_id(tag_data.category_id)
            if not category:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Category with id {tag_data.category_id} not found",
                )
        
        # Check for name conflict if name is being updated
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
        
        # No child tags anymore, so this check is removed
        # if tag.child_tags:
        #     raise HTTPException(
        #         status_code=status.HTTP_400_BAD_REQUEST,
        #         detail=f"Tag with id {tag_id} cannot be deleted because it has child tags. Please reassign or delete child tags first.",
        #     )

        self.repository.delete(tag)