#!/bin/bash

# schemas/user.py
cat > app/schemas/user.py << 'EOF'
from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime

class UserCreate(BaseModel):
    email: EmailStr
    username: str = Field(..., min_length=2, max_length=100)
    password: str = Field(..., min_length=8)
    age: Optional[int] = Field(None, ge=0, le=150)

class UserUpdate(BaseModel):
    username: Optional[str] = Field(None, min_length=2, max_length=100)
    age: Optional[int] = Field(None, ge=0, le=150)
    is_active: Optional[bool] = None

class UserResponse(BaseModel):
    id: int
    email: str
    username: str
    age: Optional[int]
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime]
    
    class Config:
        from_attributes = True
EOF

# models/user.py
cat > app/models/user.py << 'EOF'
from sqlalchemy import Column, Integer, String, DateTime, Boolean
from sqlalchemy.sql import func
from app.database import Base

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    username = Column(String(100), nullable=False)
    password = Column(String(255), nullable=False)
    age = Column(Integer)
    is_active = Column(Boolean, default=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
EOF

# repositories/user.py
cat > app/repositories/user.py << 'EOF'
from sqlalchemy.orm import Session
from typing import Optional, List
from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate

class UserRepository:
    def __init__(self, db: Session):
        self.db = db
    
    def find_by_id(self, user_id: int) -> Optional[User]:
        return self.db.query(User).filter(User.id == user_id).first()
    
    def find_by_email(self, email: str) -> Optional[User]:
        return self.db.query(User).filter(User.email == email).first()
    
    def find_all(self, skip: int = 0, limit: int = 100) -> List[User]:
        return self.db.query(User).offset(skip).limit(limit).all()
    
    def create(self, user_data: UserCreate) -> User:
        db_user = User(**user_data.model_dump())
        self.db.add(db_user)
        self.db.commit()
        self.db.refresh(db_user)
        return db_user
    
    def update(self, user: User, user_data: UserUpdate) -> User:
        update_data = user_data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(user, key, value)
        self.db.commit()
        self.db.refresh(user)
        return user
    
    def delete(self, user: User) -> None:
        self.db.delete(user)
        self.db.commit()
EOF

# services/user.py
cat > app/services/user.py << 'EOF'
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
                detail=f"User with id {user_id} not found"
            )
        return UserResponse.model_validate(user)
    
    def get_users(self, skip: int = 0, limit: int = 100) -> List[UserResponse]:
        users = self.repository.find_all(skip=skip, limit=limit)
        return [UserResponse.model_validate(user) for user in users]
    
    def create_user(self, user_data: UserCreate) -> UserResponse:
        if self.repository.find_by_email(user_data.email):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
        
        user = self.repository.create(user_data)
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
EOF

echo "✅ 모든 파일 생성 완료!"
