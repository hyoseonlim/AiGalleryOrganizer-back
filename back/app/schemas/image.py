# app/schemas/image.py
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from app.models.image import AIProcessingStatus

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from app.models.image import AIProcessingStatus

class ImageHashPayload(BaseModel):
    client_id: str
    hash: str

class ImageUploadRequest(BaseModel):
    images: List[ImageHashPayload]

class UploadInstruction(BaseModel):
    client_id: str
    image_id: int
    presigned_url: str

class DuplicateInfo(BaseModel):
    client_id: str
    existing_image_id: int

class ImageUploadResponse(BaseModel):
    uploads: List[UploadInstruction]
    duplicates: List[DuplicateInfo]

class ImageMetadata(BaseModel):
    width: int
    height: int
    file_size: Optional[int] = Field(None, alias="fileSize")
    date_taken: Optional[datetime] = Field(None, alias="dateTaken")
    mime_type: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    exif_data: Optional[Dict[str, Any]] = Field(None, alias="exifData")

class UploadCompleteRequest(BaseModel):
    image_id: int
    metadata: ImageMetadata


class UploadCompleteResponse(BaseModel):
    image_id: int
    status: str
    hash: str


class ImageViewableResponse(BaseModel):
    image_id: int
    url: str


class ImageAnalysisResult(BaseModel):
    tag_name: str
    probability: float
    category: Optional[str] = None
    category_probability: Optional[float] = None
    quality_score: Optional[float] = Field(None, ge=0, le=1)
    feature_vector: Optional[List[float]] = None
    image_url: Optional[str] = None

class ImageResponse(BaseModel):
    image_id: int = Field(alias='id')
    url: Optional[str]
    uploaded_at: datetime
    ai_processing_status: AIProcessingStatus

    class Config:
        from_attributes = True

