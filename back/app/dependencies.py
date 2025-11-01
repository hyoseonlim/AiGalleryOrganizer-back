from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from app.database import get_db
from app.repositories.image import ImageRepository
from app.repositories.user import UserRepository
from app.repositories.tag import TagRepository
from app.repositories.category import CategoryRepository
from app.repositories.similar_group_repository import SimilarGroupRepository
from app.repositories.album import AlbumRepository
from app.services.image import ImageService
from app.services.user import UserService
from app.services.tag import TagService
from app.services.category import CategoryService
from app.services.similar_group_service import SimilarGroupService
from app.services.album import AlbumService
from app.schemas.token import TokenData
from config.config import settings
from app.security import ALGORITHM

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

def get_image_repository(db: Session = Depends(get_db)) -> ImageRepository:
    return ImageRepository(db)

def get_category_repository(db: Session = Depends(get_db)) -> CategoryRepository:
    return CategoryRepository(db)

def get_tag_repository(db: Session = Depends(get_db)) -> TagRepository:
    return TagRepository(db)

def get_album_repository(db: Session = Depends(get_db)) -> AlbumRepository:
    return AlbumRepository(db)

def get_image_service(
    image_repository: ImageRepository = Depends(get_image_repository),
    category_repository: CategoryRepository = Depends(get_category_repository),
    tag_repository: TagRepository = Depends(get_tag_repository),
) -> ImageService:
    return ImageService(image_repository, category_repository, tag_repository)


def get_user_repository(db: Session = Depends(get_db)) -> UserRepository:
    return UserRepository(db)


def get_user_service(
    user_repository: UserRepository = Depends(get_user_repository),
) -> UserService:
    return UserService(user_repository)


def get_tag_service(
    tag_repository: TagRepository = Depends(get_tag_repository),
    db: Session = Depends(get_db)
) -> TagService:
    return TagService(tag_repository, CategoryRepository(db))


def get_category_service(
    category_repository: CategoryRepository = Depends(get_category_repository),
) -> CategoryService:
    return CategoryService(category_repository)


def get_similar_group_repository(db: Session = Depends(get_db)) -> SimilarGroupRepository:
    return SimilarGroupRepository(db)


def get_similar_group_service(
    similar_group_repository: SimilarGroupRepository = Depends(get_similar_group_repository),
    image_repository: ImageRepository = Depends(get_image_repository),
) -> SimilarGroupService:
    return SimilarGroupService(similar_group_repository, image_repository)


def get_album_service(
    album_repository: AlbumRepository = Depends(get_album_repository),
) -> AlbumService:
    return AlbumService(album_repository)


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    service: UserService = Depends(get_user_service),
):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
        token_data = TokenData(email=email)
    except JWTError:
        raise credentials_exception
    user = service.repository.find_by_email(email=token_data.email)
    if user is None:
        raise credentials_exception
    return user
