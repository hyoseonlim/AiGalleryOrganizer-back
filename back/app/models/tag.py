from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base

class Tag(Base):
    __tablename__ = "tags"

    id = Column("tag_id", Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, unique=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True) # nullable for general tags
    
    category_id = Column(Integer, ForeignKey("categories.category_id"), nullable=False)
    category = relationship("Category", back_populates="tags")

    user = relationship("User", back_populates="tags")
    images = relationship("ImageTag", back_populates="tag")