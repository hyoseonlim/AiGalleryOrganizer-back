# back/app/models/album.py
from sqlalchemy import Column, Integer, String, TIMESTAMP, Text, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
from sqlalchemy import Boolean

class Album(Base):
    __tablename__ = "albums"

    id = Column("album_id", Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    cover_image_id = Column(Integer, ForeignKey("images.image_id"), nullable=True)
    name = Column(String, nullable=False)
    is_user_created = Column(Boolean, nullable=False, default=True)
    description = Column(Text, nullable=True)
    created_at = Column(TIMESTAMP(timezone=True), default=func.now())

    owner = relationship("User", back_populates="albums")
    cover_image = relationship("Image")
    images = relationship("AlbumImage", back_populates="album")
