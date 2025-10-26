# app/schemas/image.py
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from app.models.image import AIProcessingStatus

class ImageUploadRequest(BaseModel):
    image_count: int = Field(..., gt=0, description="Number of images to upload")

class PresignedUrl(BaseModel):
    image_id: int
    presigned_url: str

class ImageUploadResponse(BaseModel):
    presigned_urls: List[PresignedUrl]

class UploadCompleteRequest(BaseModel):
    image_id: int

class UploadCompleteResponse(BaseModel):
    image_id: int
    status: str
    hash: str


class ImageViewableResponse(BaseModel):
    image_id: int
    url: str

class ImageResponse(BaseModel):
    image_id: int = Field(alias='id')
    url: Optional[str]
    uploaded_at: datetime
    ai_processing_status: AIProcessingStatus

    class Config:
        from_attributes = True
