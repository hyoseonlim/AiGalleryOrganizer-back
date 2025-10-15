# back/app/models/user.py
from sqlalchemy import Column, Integer, String, TIMESTAMP, BigInteger, Boolean
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    password = Column(String, nullable=False)
    username = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    storage_limit = Column(BigInteger, nullable=True)
    storage_used = Column(BigInteger, nullable=True)
    created_at = Column(TIMESTAMP(timezone=True), default=func.now(), nullable=False)
    updated_at = Column(TIMESTAMP(timezone=True), default=func.now(), onupdate=func.now(), nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    preferences = Column(JSONB, nullable=True)

    images = relationship("Image", back_populates="owner")
    albums = relationship("Album", back_populates="owner")
    tags = relationship("Tag", back_populates="user")
    search_history = relationship("SearchHistory", back_populates="user")