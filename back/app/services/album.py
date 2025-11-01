from typing import List, Optional
from app.repositories.album import AlbumRepository
from app.models import Album
from app.schemas.album import AlbumCreate, AlbumUpdate

class AlbumService:
    def __init__(self, album_repository: AlbumRepository):
        self.repository = album_repository

    def create_album(self, user_id: int, album_data: AlbumCreate) -> Album:
        album = self.repository.create_album(
            user_id=user_id,
            name=album_data.name,
            description=album_data.description,
            cover_image_id=album_data.cover_image_id,
            image_ids=album_data.image_ids
        )
        self.repository.db.commit()
        self.repository.db.refresh(album)
        return album

    def get_album_by_id(self, album_id: int, user_id: int) -> Optional[Album]:
        return self.repository.get_album_by_id(album_id, user_id)

    def get_all_albums_by_user(self, user_id: int) -> List[Album]:
        return self.repository.get_all_albums_by_user(user_id)

    def update_album(self, album_id: int, user_id: int, album_data: AlbumUpdate) -> Optional[Album]:
        album = self.repository.get_album_by_id(album_id, user_id)
        if not album:
            return None
        updated_album = self.repository.update_album(
            album=album,
            name=album_data.name,
            description=album_data.description,
            cover_image_id=album_data.cover_image_id
        )
        self.repository.db.commit()
        self.repository.db.refresh(updated_album)
        return updated_album

    def delete_album(self, album_id: int, user_id: int) -> bool:
        album = self.repository.get_album_by_id(album_id, user_id)
        if not album:
            return False
        self.repository.delete_album(album)
        self.repository.db.commit()
        return True

    def add_images_to_album(self, album_id: int, user_id: int, image_ids: List[int]):
        album = self.repository.get_album_by_id(album_id, user_id)
        if not album:
            return False # 또는 에러 처리
        self.repository.add_images_to_album(album_id, user_id, image_ids)
        self.repository.db.commit()
        return True

    def remove_images_from_album(self, album_id: int, user_id: int, image_ids: List[int]):
        album = self.repository.get_album_by_id(album_id, user_id)
        if not album:
            return False # 또는 에러 처리
        self.repository.remove_images_from_album(album_id, user_id, image_ids)
        self.repository.db.commit()
        return True
