# app/dependencies.py
from fastapi import Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.repositories.image import ImageRepository
from app.repositories.user import UserRepository
from app.services.image import ImageService
from app.services.user import UserService


def get_image_repository(db: Session = Depends(get_db)) -> ImageRepository:
    return ImageRepository(db)


def get_image_service(
    image_repository: ImageRepository = Depends(get_image_repository),
) -> ImageService:
    return ImageService(image_repository)


def get_user_repository(db: Session = Depends(get_db)) -> UserRepository:
    return UserRepository(db)


def get_user_service(
    user_repository: UserRepository = Depends(get_user_repository),
) -> UserService:
    return UserService(user_repository)