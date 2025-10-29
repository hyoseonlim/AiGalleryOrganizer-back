# back/app/models/tag.py
from sqlalchemy import Column, Integer, String, ForeignKey, Enum
from sqlalchemy.orm import relationship
from app.database import Base
import enum

class TagCategory(enum.Enum):
    OBJECT = "OBJECT"
    PERSON = "PERSON"
    LOCATION = "LOCATION"
    CUSTOM = "CUSTOM"

class Tag(Base):
    __tablename__ = "tags"

    id = Column("tag_id", Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, unique=True)
    category = Column(Enum(TagCategory), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True) # nullable for general tags
    parent_tag_id = Column(Integer, ForeignKey("tags.tag_id"), nullable=True)

    user = relationship("User", back_populates="tags")
    images = relationship("ImageTag", back_populates="tag")
    parent_tag = relationship("Tag", remote_side=[Tag.id], back_populates="child_tags")
    child_tags = relationship("Tag", back_populates="parent_tag")
