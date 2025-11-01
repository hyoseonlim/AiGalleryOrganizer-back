# back/app/schemas/similar_group.py
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from .image import ImageResponse

class SimilarGroupResponse(BaseModel):
    id: int = Field(..., alias='id')
    name: Optional[str] = None
    image_count: int
    created_at: datetime
    best_image_id: Optional[int] = None
    best_image: Optional[ImageResponse] = None

    class Config:
        from_attributes = True
        populate_by_name = True


class SimilarGroupConfirmRequest(BaseModel):
    image_ids_to_delete: List[int] = []
