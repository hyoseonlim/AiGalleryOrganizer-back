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

    user = relationship("User", back_populates="tags")
    images = relationship("ImageTag", back_populates="tag")

class TagHierarchy(Base):
    __tablename__ = "tag_hierarchy"

    id = Column(Integer, primary_key=True, index=True)
    parent_tag_id = Column(Integer, ForeignKey("tags.tag_id"), nullable=False)
    child_tag_id = Column(Integer, ForeignKey("tags.tag_id"), nullable=False)
    relation_type = Column(String, nullable=True)

    parent_tag = relationship("Tag", foreign_keys=[parent_tag_id])
    child_tag = relationship("Tag", foreign_keys=[child_tag_id])
