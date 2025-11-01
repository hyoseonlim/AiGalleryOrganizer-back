# back/app/models/similar_group_image.py
from sqlalchemy import Column, Integer, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from app.database import Base

class SimilarGroupImage(Base):
    __tablename__ = "similar_group_images"

    id = Column(Integer, primary_key=True, index=True)
    similar_group_id = Column(Integer, ForeignKey("similar_groups.similar_group_id"), nullable=False)
    image_id = Column(Integer, ForeignKey("images.image_id"), nullable=False)
    is_representative = Column(Boolean, default=False, nullable=False)

    group = relationship("SimilarGroup", back_populates="images")
    image = relationship("Image")
