from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional

from sqlalchemy.orm import Session
from app.dependencies import get_db, get_current_user # Assuming get_current_user is for authentication
from app.models.user import User # To get the current user's ID
from app.schemas.category import CategoryCreate, CategoryUpdate, CategoryResponse
from app.services.category import CategoryService
from app.repositories.category import CategoryRepository # For dependency injection

router = APIRouter(
    prefix="/categories",
    tags=["categories"],
)

# Dependency to get CategoryService
def get_category_service(db: Session = Depends(get_db)) -> CategoryService:
    repository = CategoryRepository(db)
    return CategoryService(repository)

@router.post("/", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
def create_category(
    category_data: CategoryCreate,
    service: CategoryService = Depends(get_category_service),
    current_user: User = Depends(get_current_user), # Assuming categories can be user-specific or admin-only
):
    """Create a new category."""
    # You might want to add authorization here (e.g., only admins can create categories)
    return service.create_category(category_data)

@router.get("/", response_model=List[CategoryResponse])
def get_all_categories(
    skip: int = 0,
    limit: int = 100,
    service: CategoryService = Depends(get_category_service),
    current_user: User = Depends(get_current_user), # Authentication check
):
    """Retrieve a list of all categories."""
    return service.get_categories(skip=skip, limit=limit)

@router.get("/{category_id}", response_model=CategoryResponse)
def get_category_by_id(
    category_id: int,
    service: CategoryService = Depends(get_category_service),
    current_user: User = Depends(get_current_user), # Authentication check
):
    """Retrieve a single category by its ID."""
    return service.get_category(category_id)

@router.put("/{category_id}", response_model=CategoryResponse)
def update_category(
    category_id: int,
    category_data: CategoryUpdate,
    service: CategoryService = Depends(get_category_service),
    current_user: User = Depends(get_current_user), # Authentication check
):
    """Update an existing category."""
    # You might want to add authorization here
    return service.update_category(category_id, category_data)

@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_category(
    category_id: int,
    service: CategoryService = Depends(get_category_service),
    current_user: User = Depends(get_current_user), # Authentication check
):
    """Delete a category."""
    # You might want to add authorization here
    service.delete_category(category_id)
