import numpy as np
from sklearn.cluster import DBSCAN
from sklearn.metrics.pairwise import cosine_distances
from typing import List
from app.models import SimilarGroup, Image
from app.repositories.similar_group_repository import SimilarGroupRepository
from app.repositories.image import ImageRepository

class SimilarGroupService:
    def __init__(self, similar_group_repository: SimilarGroupRepository, image_repository: ImageRepository):
        self.repository = similar_group_repository
        self.image_repository = image_repository

    def create_similar_groups(self, user_id: int, eps: float = 0.15, min_samples: int = 2) -> List[SimilarGroup]:
        """
        DBSCAN 알고리즘을 사용하여 사용자의 이미지를 그룹화하고 DB에 저장합니다.
        생성된 그룹 목록을 반환합니다.
        """
        # 1. 사용자의 모든 이미지 임베딩 가져오기
        images = self.repository.get_images_with_embeddings(user_id)
        
        if len(images) < min_samples:
            return []  # 그룹을 만들기에 이미지가 충분하지 않음

        image_ids = [image.id for image in images]
        # pgvector에서 온 문자열을 numpy 배열로 변환 (예: "[1,2,3]" -> np.array([1,2,3]))
        embeddings = np.array([np.fromstring(image.ai_embedding.strip('[]'), sep=',') for image in images])

        # 2. 코사인 거리 계산
        distances = cosine_distances(embeddings)

        # 3. DBSCAN 클러스터링 수행
        clustering = DBSCAN(
            eps=eps,
            min_samples=min_samples,
            metric='precomputed'
        )
        labels = clustering.fit_predict(distances)

        # 4. 클러스터링 결과를 DB에 저장
        self.repository.delete_groups_by_user_id(user_id)

        created_groups = []
        unique_labels = set(labels)
        for label in unique_labels:
            if label == -1:
                continue  # 아웃라이어는 그룹으로 만들지 않음

            cluster_image_indices = [i for i, label_ in enumerate(labels) if label_ == label]
            cluster_images = [images[i] for i in cluster_image_indices]
            
            if not cluster_images:
                continue

            # 점수가 가장 높은 이미지를 best_image로 선정
            best_image = max(cluster_images, key=lambda img: img.score or 0)
            
            cluster_image_ids = [img.id for img in cluster_images]
            
            new_group = self.repository.create_group_with_images(
                user_id=user_id, 
                label=label, 
                image_ids=cluster_image_ids,
                best_image_id=best_image.id
            )
            
            # 생성된 그룹 객체에 이미지 카운트를 임시 속성으로 추가
            setattr(new_group, 'image_count', len(cluster_image_ids))
            created_groups.append(new_group)

        self.repository.commit()
        
        # DB에서 id같은 정보를 다시 로드하기 위해
        for group in created_groups:
            self.repository.db.refresh(group)

        return created_groups

    def get_images_for_group(self, group_id: int, user_id: int) -> List[Image]:
        """특정 그룹에 속한 이미지 목록을 가져옵니다."""
        return self.repository.get_images_for_group(group_id, user_id)

    def get_similar_groups(self, user_id: int) -> List[SimilarGroup]:
        """사용자의 모든 유사 그룹 제안을 가져옵니다."""
        groups = self.repository.get_groups_by_user(user_id)
        for group in groups:
            # 그룹에 속한 이미지 수를 계산하여 추가합니다.
            setattr(group, 'image_count', len(group.images))
        return groups

    def reject_similar_group(self, group_id: int, user_id: int):
        """유사 그룹 제안을 거절하고 그룹을 삭제합니다."""
        group = self.repository.get_group_by_id(group_id, user_id)
        if group:
            self.repository.db.delete(group)
            self.repository.db.commit()

    def _confirm_group_and_delete_images(self, group_id: int, user_id: int, image_ids_to_delete: List[int]):
        """이미지 삭제 및 그룹 삭제 공통 로직"""
        # 1. 이미지 소프트 삭제
        if image_ids_to_delete:
            self.image_repository.soft_delete_by_ids(image_ids_to_delete, user_id)

        # 2. 유사 그룹 삭제
        group = self.repository.get_group_by_id(group_id, user_id)
        if group:
            self.repository.db.delete(group)
            self.repository.db.commit()

    def confirm_similar_group(self, group_id: int, user_id: int, image_ids_to_delete: List[int]):
        """사용자가 제공한 ID 목록을 기반으로 이미지를 삭제하고 그룹을 확정합니다."""
        self._confirm_group_and_delete_images(group_id, user_id, image_ids_to_delete)

    def confirm_best_image_for_group(self, group_id: int, user_id: int):
        """대표 이미지를 제외한 모든 이미지를 삭제하고 그룹을 확정합니다."""
        group = self.repository.get_group_by_id(group_id, user_id)
        if not group:
            return # 또는 에러 처리

        image_ids_to_delete = []
        if group.best_image_id:
            all_group_image_ids = [img.image_id for img in group.images]
            image_ids_to_delete = [img_id for img_id in all_group_image_ids if img_id != group.best_image_id]
        
        self._confirm_group_and_delete_images(group_id, user_id, image_ids_to_delete)
