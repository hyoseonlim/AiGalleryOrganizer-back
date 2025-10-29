from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from typing import List, Optional

from app.models.category import Category
from app.repositories.category import CategoryRepository
from app.schemas.category import CategoryCreate, CategoryUpdate, CategoryResponse

class CategoryService:
    def __init__(self, repository: CategoryRepository):
        self.repository = repository

    def get_category(self, category_id: int) -> Category:
        category = self.repository.find_by_id(category_id)
        if not category:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Category with id {category_id} not found",
            )
        return category

    def get_categories(self, skip: int = 0, limit: int = 100) -> List[CategoryResponse]:
        categories = self.repository.find_all(skip=skip, limit=limit)
        return [CategoryResponse.model_validate(category) for category in categories]

    def create_category(self, category_data: CategoryCreate) -> CategoryResponse:
        if self.repository.find_by_name(category_data.name):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Category with name '{category_data.name}' already exists",
            )
        category = self.repository.create(category_data)
        return CategoryResponse.model_validate(category)
    
    def update_category(self, category_id: int, category_data: CategoryUpdate) -> CategoryResponse:
        category = self.repository.find_by_id(category_id)
        if not category:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Category with id {category_id} not found"
            )
        
        if category_data.name and category_data.name != category.name:
            existing_category = self.repository.find_by_name(category_data.name)
            if existing_category and existing_category.id != category_id:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=f"Category with name '{category_data.name}' already exists",
                )

        updated_category = self.repository.update(category, category_data)
        return CategoryResponse.model_validate(updated_category)
    
    def delete_category(self, category_id: int) -> None:
        category = self.repository.find_by_id(category_id)
        if not category:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Category with id {category_id} not found"
            )
        
        # Optional: Check if any tags are associated with this category before deleting
        # If so, disallow deletion or reassign tags.
        # For simplicity, let's disallow deletion if it has associated tags for now.
        if category.tags: # Assuming 'tags' relationship is defined in Category model
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Category with id {category_id} cannot be deleted because it has associated tags. Please reassign or delete tags first.",
            )

        self.repository.delete(category)
