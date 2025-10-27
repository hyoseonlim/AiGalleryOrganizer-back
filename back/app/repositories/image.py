# app/repositories/image.py
from sqlalchemy.orm import Session
from app.models.image import Image
from app.models.user import User
from typing import List

class ImageRepository:
    def __init__(self, db: Session):
        self.db = db

    def create(self, **kwargs) -> Image:
        """Create a new image record."""
        new_image = Image(**kwargs)
        self.db.add(new_image)
        self.db.commit()
        self.db.refresh(new_image)
        return new_image

    def find_by_id(self, image_id: int, user_id: int) -> Image | None:
        """Find an image by its ID and user, excluding soft-deleted images."""
        return self.db.query(Image).filter(
            Image.id == image_id, 
            Image.user_id == user_id, 
            Image.deleted_at.is_(None)
        ).first()

    def find_by_id_including_trashed(self, image_id: int, user_id: int) -> Image | None:
        """Find an image by its ID and user, including soft-deleted images."""
        return self.db.query(Image).filter(Image.id == image_id, Image.user_id == user_id).first()

    def find_by_hash(self, image_hash: str) -> Image | None:
        """Find an image by its hash."""
        return self.db.query(Image).filter(Image.hash == image_hash, Image.deleted_at.is_(None)).first()

    def find_all_by_user(self, user_id: int) -> List[Image]:
        """Find all images for a user, excluding soft-deleted ones."""
        return self.db.query(Image).filter(Image.user_id == user_id, Image.deleted_at.is_(None)).all()

    def find_trashed_by_user(self, user_id: int) -> List[Image]:
        """Find all soft-deleted images for a user."""
        return self.db.query(Image).filter(Image.user_id == user_id, Image.deleted_at.isnot(None)).all()

    def update(self, image: Image, **kwargs) -> Image:
        """Update an image record."""
        for key, value in kwargs.items():
            setattr(image, key, value)
        self.db.commit()
        self.db.refresh(image)
        return image

    def delete_permanently(self, image: Image) -> None:
        """Permanently delete an image record."""
        self.db.delete(image)
        self.db.commit()
