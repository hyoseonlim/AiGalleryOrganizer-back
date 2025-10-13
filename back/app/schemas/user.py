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
