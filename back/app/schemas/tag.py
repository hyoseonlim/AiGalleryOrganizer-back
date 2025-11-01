from pydantic import BaseModel, Field
from typing import Optional
from app.schemas.category import CategoryResponse # Import CategoryResponse

class TagBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)

class TagCreate(TagBase):
    category_id: int # Added

class TagUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    category_id: Optional[int] = None # Added

class TagResponse(TagBase):
    id: int
    user_id: Optional[int]
    category_id: int # Added
    category: CategoryResponse # Added

    class Config:
        from_attributes = True

# TagBaseResponse is no longer needed
# TagResponse.model_rebuild() is no longer needed as TagResponse is not recursive