# back/app/models/image.py
from sqlalchemy import Column, Integer, String, TIMESTAMP, ForeignKey, Enum
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

# AI 처리 상태 Enum
import enum
class AIProcessingStatus(enum.Enum):
    PENDING = "PENDING"
    PROCESSING = "PROCESSING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"

class Image(Base):
    __tablename__ = "image"

    image_id = Column(Integer, primary_key=True, index=True) # PK
    user_id = Column(Integer, ForeignKey("user.id"), nullable=False) # FK (유저ID)
    
    path = Column(String, nullable=False)
    hash = Column(String, nullable=False)
    size = Column(Integer, nullable=False)
    uploaded_at = Column(TIMESTAMP(timezone=True), default=func.now(), nullable=False)
    deleted_at = Column(TIMESTAMP(timezone=True), nullable=True) # default null
    
    # VECTOR(512)는 String으로 대체 (실제로는 pgvector 확장과 함께 TypeDecorator 사용 필요)
    ai_embedding = Column(String, nullable=False) 
    metadata = Column(JSONB, nullable=True)
    type = Column(Enum(AIProcessingStatus), default=AIProcessingStatus.PENDING, nullable=False)

    # Relationship 정의 (선택적)
    owner = relationship("User")