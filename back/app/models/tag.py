# back/app/models/tag.py
from sqlalchemy import Column, Integer, String, ForeignKey # Removed Enum
from sqlalchemy.orm import relationship
from app.database import Base
# import enum # No longer needed

from app.models.category import Category # Import Category

# TagCategory enum is no longer needed
# class TagCategory(enum.Enum):
#     LANDSCAPE = "LANDSCAPE"
#     PEOPLE = "PEOPLE"
#     ANIMAL = "ANIMAL"
#     FOOD = "FOOD"
#     CITY = "CITY"
#     CUSTOM = "CUSTOM"

class Tag(Base):
    __tablename__ = "tags"

    id = Column("tag_id", Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, unique=True)
    # category = Column(Enum(TagCategory), nullable=False) # Removed
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True) # nullable for general tags
    # parent_tag_id = Column(Integer, ForeignKey("tags.tag_id"), nullable=True) # Removed
    
    # New category_id column and relationship
    category_id = Column(Integer, ForeignKey("categories.category_id"), nullable=False)
    category = relationship("Category", back_populates="tags")

    user = relationship("User", back_populates="tags")
    images = relationship("ImageTag", back_populates="tag")
    # parent_tag = relationship("Tag", remote_side=lambda: [Tag.id], back_populates="child_tags") # Removed
    # child_tags = relationship("Tag", back_populates="parent_tag") # Removed

# TagHierarchy is no longer needed
# class TagHierarchy(Base):
#     __tablename__ = "tag_hierarchy"
#
#     id = Column(Integer, primary_key=True, index=True)
#     parent_tag_id = Column(Integer, ForeignKey("tags.tag_id"), nullable=False)
#     child_tag_id = Column(Integer, ForeignKey("tags.tag_id"), nullable=False)
#     relation_type = Column(String, nullable=True)
#
#     parent_tag = relationship("Tag", foreign_keys=[parent_tag_id])
#     child_tag = relationship("Tag", foreign_keys=[child_tag_id])