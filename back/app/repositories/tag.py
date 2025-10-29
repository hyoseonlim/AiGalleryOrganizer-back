from sqlalchemy.orm import Session, joinedload
from sqlalchemy import or_
from typing import Optional, List, Dict, Any
from app.models import Tag
from app.schemas.tag import TagCreate, TagUpdate

class TagRepository:
    def __init__(self, db: Session):
        self.db = db

    def find_by_id(self, tag_id: int) -> Optional[Tag]:
        return self.db.query(Tag).options(
            joinedload(Tag.category) # Eager-load category
        ).filter(Tag.id == tag_id).first()

    def find_by_name(self, name: str) -> Optional[Tag]:
        return self.db.query(Tag).filter(Tag.name == name).first()

    def find_tags_for_user(self, user_id: int, skip: int = 0, limit: int = 100) -> List[Tag]:
        return self.db.query(Tag).options(
            joinedload(Tag.category) # Eager-load category
        ).filter(
            or_(Tag.user_id == None, Tag.user_id == user_id)
        ).offset(skip).limit(limit).all()

    def create(self, tag_data: TagCreate, user_id: Optional[int] = None) -> Tag:
        db_tag = Tag(**tag_data.model_dump(exclude_unset=True))
        if user_id:
            db_tag.user_id = user_id
        # category_id is now part of tag_data, no special handling needed here
        self.db.add(db_tag)
        self.db.commit()
        self.db.refresh(db_tag)
        return db_tag

    def update(self, tag: Tag, tag_data: TagUpdate) -> Tag:
        update_data = tag_data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(tag, key, value)
        self.db.commit()
        self.db.refresh(tag)
        return tag

    def delete(self, tag: Tag) -> None:
        self.db.delete(tag)
        self.db.commit()