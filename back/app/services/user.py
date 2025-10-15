from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from typing import List

from app.repositories.user import UserRepository
from app.schemas.user import UserCreate, UserUpdate, UserResponse


class UserService:
    def __init__(self, db: Session):
        self.repository = UserRepository(db)

    def get_user(self, user_id: int) -> UserResponse:
        user = self.repository.find_by_id(user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User with id {user_id} not found",
            )
        return UserResponse.model_validate(user)

    def get_users(self, skip: int = 0, limit: int = 100) -> List[UserResponse]:
        users = self.repository.find_all(skip=skip, limit=limit)
        return [UserResponse.model_validate(user) for user in users]

    def create_user(self, user_data: UserCreate) -> UserResponse:
        if self.repository.find_by_email(user_data.email):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered",
            )
        
        user_dict = user_data.model_dump()
        
        user = self.repository.create(user_dict)
        return UserResponse.model_validate(user)
    
    def update_user(self, user_id: int, user_data: UserUpdate) -> UserResponse:
        user = self.repository.find_by_id(user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User with id {user_id} not found"
            )
        
        updated_user = self.repository.update(user, user_data)
        return UserResponse.model_validate(updated_user)
    
    def delete_user(self, user_id: int) -> None:
        user = self.repository.find_by_id(user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User with id {user_id} not found"
            )
        
        self.repository.delete(user)
