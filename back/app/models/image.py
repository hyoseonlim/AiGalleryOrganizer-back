# back/app/models/image.py
from sqlalchemy import Column, Integer, String, TIMESTAMP, ForeignKey, Enum, Float, Boolean
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import enum

class AIProcessingStatus(enum.Enum):
    PENDING = "PENDING"
    PROCESSING = "PROCESSING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"

class Image(Base):
    __tablename__ = "images"

    id = Column("image_id", Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    url = Column(String, nullable=True)
    hash = Column(String, nullable=True, unique=True)
    size = Column(Integer, nullable=True)
    is_saved = Column(Boolean, default=False, nullable=False)
    uploaded_at = Column(TIMESTAMP(timezone=True), default=func.now(), nullable=False)
    deleted_at = Column(TIMESTAMP(timezone=True), nullable=True)
    ai_embedding = Column(String) # pgvector의 VECTOR(512) 타입에 해당
    exif = Column(JSONB, nullable=True)
    ai_processing_status = Column(Enum(AIProcessingStatus), default=AIProcessingStatus.PENDING)

    owner = relationship("User", back_populates="images")
    tags = relationship("ImageTag", back_populates="image")
    albums = relationship("AlbumImage", back_populates="image")

class AIProcessingQueue(Base):
    __tablename__ = "ai_processing_queue"

    id = Column(Integer, primary_key=True, index=True)
    image_id = Column(Integer, ForeignKey("images.image_id"), nullable=False)
    status = Column(Enum(AIProcessingStatus), default=AIProcessingStatus.PENDING)
    created_at = Column(TIMESTAMP(timezone=True), default=func.now())
    started_at = Column(TIMESTAMP(timezone=True), nullable=True)
    completed_at = Column(TIMESTAMP(timezone=True), nullable=True)

    image = relationship("Image")
