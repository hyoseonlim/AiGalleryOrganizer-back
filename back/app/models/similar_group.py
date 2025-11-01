# back/app/models/similar_group.py
from sqlalchemy import Column, Integer, String, TIMESTAMP, ForeignKey, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import enum

class SimilarGroupStatus(enum.Enum):
    SUGGESTED = "suggested"
    CREATED = "created"
    REJECTED = "rejected"

class SimilarGroup(Base):
    __tablename__ = "similar_groups"

    id = Column("similar_group_id", Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String, nullable=True)
    status = Column(Enum(SimilarGroupStatus), nullable=False, default=SimilarGroupStatus.SUGGESTED)
    created_at = Column(TIMESTAMP(timezone=True), default=func.now())

    user = relationship("User")
    images = relationship("SimilarGroupImage", back_populates="group")
