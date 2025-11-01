# back/app/services/similar_photo_group_service.py
import numpy as np
from sklearn.cluster import DBSCAN
from sklearn.metrics.pairwise import cosine_distances
from sqlalchemy.orm import Session
from app.models import Image, SimilarPhotoGroup, SimilarPhotoGroupImage
from app.models.similar_photo_group import SimilarPhotoGroupStatus

def create_similar_photo_groups(db: Session, user_id: int, eps: float = 0.15, min_samples: int = 2):
    """
    DBSCAN 알고리즘을 사용하여 사용자의 이미지를 그룹화하고 DB에 저장합니다.

    :param db: SQLAlchemy Session 객체
    :param user_id: 사용자 ID
    :param eps: DBSCAN의 eps 파라미터 (유사도 임계값)
    :param min_samples: DBSCAN의 min_samples 파라미터 (그룹 최소 이미지 수)
    """
    # 1. 사용자의 모든 이미지 임베딩 가져오기
    images = db.query(Image).filter(Image.user_id == user_id, Image.ai_embedding.isnot(None)).all()
    
    if len(images) < min_samples:
        return 0, 0 # 그룹을 만들기에 이미지가 충분하지 않음

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
    n_clusters = len(set(labels)) - (1 if -1 in labels else 0)
    
    # 기존의 제안된 그룹 삭제
    db.query(SimilarPhotoGroup).filter(
        SimilarPhotoGroup.user_id == user_id,
        SimilarPhotoGroup.status == SimilarPhotoGroupStatus.SUGGESTED
    ).delete()

    for label in set(labels):
        if label == -1:
            continue  # 아웃라이어는 그룹으로 만들지 않음

        cluster_image_ids = [image_ids[i] for i, label_ in enumerate(labels) if label_ == label]
        
        # 새 그룹 생성
        new_group = SimilarPhotoGroup(
            user_id=user_id,
            name=f"Suggested Group {label + 1}", # 간단한 이름 생성
            status=SimilarPhotoGroupStatus.SUGGESTED
        )
        db.add(new_group)
        db.flush() # new_group.id를 얻기 위해 flush

        # 그룹에 이미지 연결
        for image_id in cluster_image_ids:
            new_group_image = SimilarPhotoGroupImage(
                similar_photo_group_id=new_group.id,
                image_id=image_id
            )
            db.add(new_group_image)

    db.commit()

    n_outliers = list(labels).count(-1)
    return n_clusters, n_outliers
