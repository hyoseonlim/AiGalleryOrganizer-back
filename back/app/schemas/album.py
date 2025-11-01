from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from .image import ImageResponse

class AlbumCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    cover_image_id: Optional[int] = None
    image_ids: Optional[List[int]] = None

class AlbumUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    cover_image_id: Optional[int] = None

class AlbumResponse(BaseModel):
    id: int = Field(..., alias='album_id')
    name: str
    description: Optional[str] = None
    created_at: datetime
    cover_image_id: Optional[int] = None
    cover_image: Optional[ImageResponse] = None
    image_count: int = 0 # 앨범에 포함된 이미지 수

    class Config:
        from_attributes = True
        populate_by_name = True

class AlbumImageRequest(BaseModel):
    image_ids: List[int]
