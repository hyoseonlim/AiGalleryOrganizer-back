# app/repositories/image.py
from sqlalchemy.orm import Session
from app.models.image import Image
from app.models.association import ImageTag
from app.models.tag import Tag
from typing import List

class ImageRepository:
    def __init__(self, db: Session):
        self.db = db

    def create(self, **kwargs) -> Image:
        """새 이미지 레코드를 생성합니다."""
        new_image = Image(**kwargs)
        self.db.add(new_image)
        self.db.flush()
        self.db.refresh(new_image)
        return new_image

    def find_by_id(self, image_id: int, user_id: int) -> Image | None:
        """ID와 사용자로 이미지를 찾습니다 (소프트 삭제된 이미지 제외)."""
        return self.db.query(Image).filter(
            Image.id == image_id, 
            Image.user_id == user_id, 
            Image.deleted_at.is_(None)
        ).first()

    def find_by_id_for_analysis(self, image_id: int) -> Image | None:
        """분석 콜백을 위해 사용자 또는 소프트 삭제 필터링 없이 ID로 이미지를 찾습니다."""
        return self.db.query(Image).filter(Image.id == image_id).first()

    def find_by_id_including_trashed(self, image_id: int, user_id: int) -> Image | None:
        """ID와 사용자로 이미지를 찾습니다 (소프트 삭제된 이미지 포함)."""
        return self.db.query(Image).filter(Image.id == image_id, Image.user_id == user_id).first()

    def find_by_hash(self, image_hash: str) -> Image | None:
        """해시로 이미지를 찾습니다."""
        return self.db.query(Image).filter(Image.hash == image_hash, Image.deleted_at.is_(None)).first()

    def find_all_by_user(self, user_id: int, skip: int = 0, limit: int = 100) -> List[Image]:
        """사용자의 모든 이미지를 찾습니다 (소프트 삭제된 이미지 제외)."""
        return self.db.query(Image).filter(Image.user_id == user_id, Image.deleted_at.is_(None)).offset(skip).limit(limit).all()

    def find_trashed_by_user(self, user_id: int) -> List[Image]:
        """사용자의 모든 소프트 삭제된 이미지를 찾습니다."""
        return self.db.query(Image).filter(Image.user_id == user_id, Image.deleted_at.isnot(None)).all()

    def update(self, image: Image, **kwargs) -> Image:
        """이미지 레코드를 업데이트합니다."""
        for key, value in kwargs.items():
            setattr(image, key, value)
        return image

    def delete_permanently(self, image: Image) -> None:
        """이미지 레코드를 영구적으로 삭제합니다."""
        self.db.delete(image)

    def soft_delete_by_ids(self, image_ids: List[int], user_id: int):
        """ID 목록으로 이미지를 소프트 삭제합니다."""
        from datetime import datetime, timezone

        self.db.query(Image).filter(
            Image.id.in_(image_ids),
            Image.user_id == user_id
        ).update({Image.deleted_at: datetime.now(timezone.utc)}, synchronize_session=False)

    def add_tags_to_image(self, image: Image, tags: List[Tag]):
        """이미지에 태그 목록을 추가합니다."""
        for tag in tags:
            # Check if association already exists
            exists = self.db.query(ImageTag).filter_by(image_id=image.id, tag_id=tag.id).first()
            if not exists:
                image_tag = ImageTag(image_id=image.id, tag_id=tag.id)
                self.db.add(image_tag)

    def remove_tags_from_image(self, image: Image, tags: List[Tag]):
        """이미지에서 태그 목록을 제거합니다."""
        tag_ids = [tag.id for tag in tags]
        self.db.query(ImageTag).filter(
            ImageTag.image_id == image.id,
            ImageTag.tag_id.in_(tag_ids)
        ).delete(synchronize_session=False)
