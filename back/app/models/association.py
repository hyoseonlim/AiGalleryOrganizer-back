# back/app/models/association.py
# 중간 테이블 및 검색 기록
from sqlalchemy import Column, Integer, TIMESTAMP, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql import func
from app.database import Base

class AlbumImage(Base):
    __tablename__ = "album_image"

    id = Column(Integer, primary_key=True, index=True) # PK
    album_id = Column(Integer, ForeignKey("album.album_id"), nullable=False) # PK, FK
    image_id = Column(Integer, ForeignKey("image.image_id"), nullable=False) # PK, FK
    user_id = Column(Integer, ForeignKey("user.id"), nullable=False) # PK, FK
    
    created_at = Column(TIMESTAMP(timezone=True), default=func.now(), nullable=False)

    # Relationship 정의 (선택적)
    album = relationship("Album")
    image = relationship("Image")
    user = relationship("User")


class ImageTag(Base):
    __tablename__ = "image_tag"

    image_tag_id = Column(Integer, primary_key=True, index=True) # PK
    image_id = Column(Integer, ForeignKey("image.image_id"), nullable=False) # PK, FK
    tag_id = Column(Integer, ForeignKey("tag.tag_id"), nullable=False) # PK, FK
    
    confidence = Column(Float, nullable=False)
    created_at = Column(TIMESTAMP(timezone=True), default=func.now(), nullable=False)
    # VECTOR(512)는 String으로 대체 (실제로는 pgvector 확장과 함께 TypeDecorator 사용 필요)
    image_tag_embedding = Column(String, nullable=False) 

    # Relationship 정의 (선택적)
    image = relationship("Image")
    tag = relationship("Tag")


class TagHierarchy(Base):
    __tablename__ = "tag_hierarchy"

    id = Column(Integer, primary_key=True, index=True) # PK
    parent_tag_id = Column(Integer, ForeignKey("tag.tag_id"), nullable=True) # PK, FK
    child_tag_id = Column(Integer, ForeignKey("tag.tag_id"), nullable=True) # FK
    
    relation_type = Column(String, nullable=False)
    created_at = Column(TIMESTAMP(timezone=True), default=func.now(), nullable=False)

    # Relationship 정의 (선택적)
    parent_tag = relationship("Tag", foreign_keys=[parent_tag_id], remote_side=[Tag.tag_id])
    child_tag = relationship("Tag", foreign_keys=[child_tag_id], remote_side=[Tag.tag_id])


class SearchHistory(Base):
    __tablename__ = "search_history"

    id = Column(Integer, primary_key=True, index=True) # PK
    user_id = Column(Integer, ForeignKey("user.id"), nullable=False) # PK, FK
    
    query = Column(JSONB, nullable=True)
    filters = Column(JSONB, nullable=True)
    # created_at (생성일시)가 테이블 정의에 없지만, 관례상 추가하는 경우가 많아 제외했습니다.

    # Relationship 정의 (선택적)
    user = relationship("User")