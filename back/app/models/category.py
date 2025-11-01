from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship
from app.database import Base

class Category(Base):
    __tablename__ = "categories"

    id = Column("category_id", Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, unique=True)

    tags = relationship("Tag", back_populates="category")