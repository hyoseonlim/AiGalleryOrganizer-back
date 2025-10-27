# back/app/models/association.py
from sqlalchemy import Column, Integer, TIMESTAMP, ForeignKey, Float, String
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql import func
from app.database import Base

class AlbumImage(Base):
    __tablename__ = "album_images"

    id = Column(Integer, primary_key=True, index=True)
    album_id = Column(Integer, ForeignKey("albums.album_id"), nullable=False)
    image_id = Column(Integer, ForeignKey("images.image_id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(TIMESTAMP(timezone=True), default=func.now())

    album = relationship("Album", back_populates="images")
    image = relationship("Image", back_populates="albums")

class ImageTag(Base):
    __tablename__ = "image_tags"

    id = Column("image_tag_id", Integer, primary_key=True, index=True)
    image_id = Column(Integer, ForeignKey("images.image_id"), nullable=False)
    tag_id = Column(Integer, ForeignKey("tags.tag_id"), nullable=False)
    confidence = Column(Float, nullable=True)
    created_at = Column(TIMESTAMP(timezone=True), default=func.now())
    image_tag_embedding = Column(String) # pgvector의 VECTOR(512) 타입에 해당

    image = relationship("Image", back_populates="tags")
    tag = relationship("Tag", back_populates="images")

class SearchHistory(Base):
    __tablename__ = "search_history"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    query = Column(JSONB, nullable=True)
    filters = Column(JSONB, nullable=True)

    user = relationship("User", back_populates="search_history")
