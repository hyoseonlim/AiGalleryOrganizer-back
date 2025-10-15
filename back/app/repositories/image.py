# app/repositories/image.py
from sqlalchemy.orm import Session
from app.models.image import Image

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

    def find_by_id(self, image_id: int) -> Image | None:
        """Find an image by its ID."""
        return self.db.query(Image).filter(Image.id == image_id).first()

    def find_by_hash(self, image_hash: str) -> Image | None:
        """Find an image by its hash."""
        return self.db.query(Image).filter(Image.hash == image_hash).first()

    def update(self, image: Image, **kwargs) -> Image:
        """Update an image record."""
        for key, value in kwargs.items():
            setattr(image, key, value)
        self.db.commit()
        self.db.refresh(image)
        return image

    def delete(self, image: Image) -> None:
        """Delete an image record."""
        self.db.delete(image)
        self.db.commit()
