# back/app/schemas/similar_group.py
from pydantic import BaseModel

class SimilarGroupResponse(BaseModel):
    id: int
    name: str
    image_count: int

    class Config:
        orm_mode = True
