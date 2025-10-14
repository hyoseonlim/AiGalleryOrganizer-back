# back/app/models/album.py
from sqlalchemy import Column, Integer, String, TIMESTAMP, Text, ForeignKey, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

# type은 PostgreSQL의 ENUM 타입을 활용하거나 String으로 대체 가능.
# 여기서는 String과 CHECK 제약조건을 사용하는 것이 일반적입니다.
# Enum을 정의하고 사용하는 것이 더 깔끔합니다.
import enum
class AlbumType(enum.Enum):
    PUBLIC = "PUBLIC"
    PRIVATE = "PRIVATE"
    SHARED = "SHARED"

class Album(Base):
    __tablename__ = "album"

    album_id = Column(Integer, primary_key=True, index=True) # PK
    user_id = Column(Integer, ForeignKey("user.id"), nullable=False) # FK (유저ID)
    cover_image_id = Column(Integer, ForeignKey("image.image_id"), nullable=False) # FK (커버이미지)
    
    name = Column(String, nullable=False)
    # Enum 타입을 사용하거나, 문자열로 정의하고 애플리케이션 레벨에서 유효성 검사
    type = Column(Enum(AlbumType), default=AlbumType.PRIVATE, nullable=False) 
    description = Column(Text, nullable=True)
    created_at = Column(TIMESTAMP(timezone=True), default=func.now(), nullable=False)

    # Relationship 정의 (선택적)
    owner = relationship("User")
    cover_image = relationship("Image", foreign_keys=[cover_image_id])