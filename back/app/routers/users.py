# app/routers/users.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.database import get_db
from app.schemas.user import UserCreate, UserUpdate, UserResponse
from app.services.user import UserService

router = APIRouter()

@router.get("/", response_model=List[UserResponse])
def get_users(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """사용자 목록 조회"""
    service = UserService(db)
    return service.get_users(skip=skip, limit=limit)

@router.get("/{user_id}", response_model=UserResponse)
def get_user(
    user_id: int,
    db: Session = Depends(get_db)
):
    """특정 사용자 조회"""
    service = UserService(db)
    return service.get_user(user_id)

@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def create_user(
    user_data: UserCreate,
    db: Session = Depends(get_db)
):
    """사용자 생성"""
    service = UserService(db)
    return service.create_user(user_data)

@router.put("/{user_id}", response_model=UserResponse)
def update_user(
    user_id: int,
    user_data: UserUpdate,
    db: Session = Depends(get_db)
):
    """사용자 수정"""
    service = UserService(db)
    return service.update_user(user_id, user_data)

@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(
    user_id: int,
    db: Session = Depends(get_db)
):
    """사용자 삭제"""
    service = UserService(db)
    service.delete_user(user_id)