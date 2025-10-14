# back/app/models/tag.py
from sqlalchemy import Column, Integer, String, ForeignKey, Enum
from sqlalchemy.orm import relationship
from app.database import Base

# 카테고리 Enum (예시)
import enum
class TagCategory(enum.Enum):
    OBJECT = "OBJECT"
    PEOPLE = "PEOPLE"
    LOCATION = "LOCATION"
    CUSTOM = "CUSTOM"

class Tag(Base):
    __tablename__ = "tag"

    tag_id = Column(Integer, primary_key=True, index=True) # PK
    user_id = Column(Integer, ForeignKey("user.id"), nullable=True) # FK (사용자인 경우만 존재)
    
    name = Column(String, nullable=False)
    # Enum 타입을 사용
    category = Column(Enum(TagCategory), nullable=False)

    # Relationship 정의 (선택적)
    user = relationship("User")