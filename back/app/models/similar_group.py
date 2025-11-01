# back/app/models/similar_group.py
from sqlalchemy import Column, Integer, String, TIMESTAMP, ForeignKey, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import enum


class SimilarGroup(Base):
    __tablename__ = "similar_groups"

    id = Column("similar_group_id", Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String, nullable=True)
    created_at = Column(TIMESTAMP(timezone=True), default=func.now())
    best_image_id = Column(Integer, ForeignKey("images.image_id"), nullable=True)

    user = relationship("User")
    images = relationship("SimilarGroupImage", back_populates="group", cascade="all, delete-orphan")
    best_image = relationship("Image")
