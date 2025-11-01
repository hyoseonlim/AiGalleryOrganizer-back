# back/app/repositories/similar_group_repository.py
from sqlalchemy.orm import Session
from typing import List
from app.models import Image, SimilarGroup, SimilarGroupImage
from app.models.similar_group import SimilarGroupStatus

class SimilarGroupRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_images_with_embeddings(self, user_id: int) -> List[Image]:
        """사용자의 모든 이미지와 임베딩을 가져옵니다."""
        return self.db.query(Image).filter(
            Image.user_id == user_id, 
            Image.ai_embedding.isnot(None),
            Image.deleted_at.is_(None)
        ).all()

    def delete_suggested_groups(self, user_id: int) -> int:
        """기존에 제안된 그룹을 삭제합니다."""
        num_deleted = self.db.query(SimilarGroup).filter(
            SimilarGroup.user_id == user_id,
            SimilarGroup.status == SimilarGroupStatus.SUGGESTED
        ).delete()
        return num_deleted

    def create_group_with_images(self, user_id: int, label: int, image_ids: List[int]) -> SimilarGroup:
        """새로운 유사 그룹과 이미지 연결을 생성합니다."""
        # 새 그룹 생성
        new_group = SimilarGroup(
            user_id=user_id,
            name=f"Suggested Group {label + 1}",
            status=SimilarGroupStatus.SUGGESTED
        )
        self.db.add(new_group)
        self.db.flush()  # new_group.id를 얻기 위해

        # 그룹에 이미지 연결
        for image_id in image_ids:
            new_group_image = SimilarGroupImage(
                similar_group_id=new_group.id,
                image_id=image_id
            )
            self.db.add(new_group_image)
        
        return new_group

    def commit(self):
        """DB 변경사항을 커밋합니다."""
        self.db.commit()

    def get_images_for_group(self, group_id: int, user_id: int) -> List[Image]:
        """특정 그룹에 속한 이미지 목록을 가져옵니다."""
        return self.db.query(Image).join(SimilarGroupImage).join(SimilarGroup).filter(
            SimilarGroup.id == group_id,
            SimilarGroup.user_id == user_id,
            Image.deleted_at.is_(None)
        ).all()
