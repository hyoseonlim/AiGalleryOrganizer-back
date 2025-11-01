from sqlalchemy.orm import Session
from typing import List, Optional
from app.models import Album, AlbumImage, Image

class AlbumRepository:
    def __init__(self, db: Session):
        self.db = db

    def create_album(self, user_id: int, name: str, description: Optional[str] = None, cover_image_id: Optional[int] = None, image_ids: Optional[List[int]] = None) -> Album:
        new_album = Album(
            user_id=user_id,
            name=name,
            description=description,
            cover_image_id=cover_image_id
        )
        self.db.add(new_album)
        self.db.flush() # To get the new album's ID

        if image_ids:
            self.add_images_to_album(new_album.id, user_id, image_ids)

        self.db.refresh(new_album)
        return new_album

    def get_album_by_id(self, album_id: int, user_id: int) -> Optional[Album]:
        return self.db.query(Album).filter(Album.id == album_id, Album.user_id == user_id).first()

    def get_all_albums_by_user(self, user_id: int) -> List[Album]:
        return self.db.query(Album).filter(Album.user_id == user_id).all()

    def update_album(self, album: Album, name: Optional[str] = None, description: Optional[str] = None, cover_image_id: Optional[int] = None) -> Album:
        if name is not None: 
            album.name = name
        if description is not None:
            album.description = description
        if cover_image_id is not None:
            album.cover_image_id = cover_image_id
        return album

    def delete_album(self, album: Album):
        self.db.delete(album)

    def add_images_to_album(self, album_id: int, user_id: int, image_ids: List[int]):
        existing_image_ids = self.db.query(AlbumImage.image_id).filter(
            AlbumImage.album_id == album_id,
            AlbumImage.user_id == user_id,
            AlbumImage.image_id.in_(image_ids)
        ).all()
        existing_image_ids = {img_id for (img_id,) in existing_image_ids}

        new_album_images = []
        for image_id in image_ids:
            if image_id not in existing_image_ids:
                # Check if image exists and belongs to the user
                image_exists = self.db.query(Image).filter(Image.id == image_id, Image.user_id == user_id).first()
                if image_exists:
                    new_album_images.append(AlbumImage(album_id=album_id, image_id=image_id, user_id=user_id))
        
        if new_album_images:
            self.db.add_all(new_album_images)

    def remove_images_from_album(self, album_id: int, user_id: int, image_ids: List[int]):
        self.db.query(AlbumImage).filter(
            AlbumImage.album_id == album_id,
            AlbumImage.user_id == user_id,
            AlbumImage.image_id.in_(image_ids)
        ).delete(synchronize_session=False)
