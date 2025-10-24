# app/schemas/image.py
from pydantic import BaseModel, Field
from typing import List

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
