# app/routers/users.py
from fastapi import APIRouter, Depends, HTTPException, status
from typing import List

from app.dependencies import get_user_service, get_current_user, get_image_service
from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate, UserResponse
from app.schemas.image import ImageResponse
from app.services.user import UserService
from app.services.image import ImageService

router = APIRouter(
    prefix="/users",
    tags=["users"],
)

@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def create_user(
    user_data: UserCreate,
    service: UserService = Depends(get_user_service),
):
    """사용자 생성"""
    return service.create_user(user_data)

@router.get("/me", response_model=UserResponse)
async def read_users_me(current_user: User = Depends(get_current_user)):
    """현재 사용자 정보 조회"""
    return current_user

@router.get("/me/images", response_model=List[ImageResponse])
def get_my_images(
    image_service: ImageService = Depends(get_image_service),
    current_user: User = Depends(get_current_user),
):
    """Get all images for the current user."""
    return image_service.get_all_images_by_user(user=current_user)

@router.get("/{user_id}", response_model=UserResponse)
def get_user(
    user_id: int,
    service: UserService = Depends(get_user_service),
    current_user: User = Depends(get_current_user),
):
    """특정 사용자 조회"""
    return service.get_user(user_id)

@router.get("/", response_model=List[UserResponse])
def get_users(
    skip: int = 0,
    limit: int = 100,
    service: UserService = Depends(get_user_service),
    current_user: User = Depends(get_current_user),
):
    """사용자 목록 조회"""
    return service.get_users(skip=skip, limit=limit)

@router.put("/{user_id}", response_model=UserResponse)
def update_user(
    user_id: int,
    user_data: UserUpdate,
    service: UserService = Depends(get_user_service),
    current_user: User = Depends(get_current_user),
):
    """사용자 수정"""
    return service.update_user(user_id, user_data)

@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(
    user_id: int,
    service: UserService = Depends(get_user_service),
    current_user: User = Depends(get_current_user),
):
    """사용자 삭제"""
    service.delete_user(user_id)