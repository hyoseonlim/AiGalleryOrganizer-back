import numpy as np
from sklearn.cluster import DBSCAN
from sklearn.metrics.pairwise import cosine_distances
from typing import List
from app.models import SimilarGroup
from app.repositories.similar_group_repository import SimilarGroupRepository

class SimilarGroupService:
    def __init__(self, similar_group_repository: SimilarGroupRepository):
        self.repository = similar_group_repository

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
        self.repository.delete_suggested_groups(user_id)

        created_groups = []
        unique_labels = set(labels)
        for label in unique_labels:
            if label == -1:
                continue  # 아웃라이어는 그룹으로 만들지 않음

            cluster_image_ids = [image_ids[i] for i, l in enumerate(labels) if l == label]
            new_group = self.repository.create_group_with_images(user_id, label, cluster_image_ids)
            
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
