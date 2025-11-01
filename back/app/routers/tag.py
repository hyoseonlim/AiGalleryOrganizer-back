from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional

from sqlalchemy.orm import Session
from app.dependencies import get_db, get_current_user, get_tag_service
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
    """Create a new tag."""
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
    """Retrieve a list of all tags visible to the current user."""
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
    """Retrieve a single tag by its ID."""
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
    """Update an existing tag."""
    return service.update_tag(tag_id, tag_data)

@router.delete("/{tag_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_tag(
    tag_id: int,
    service: TagService = Depends(get_tag_service),
    current_user: User = Depends(get_current_user),
):
    """Delete a tag."""
    service.delete_tag(tag_id)