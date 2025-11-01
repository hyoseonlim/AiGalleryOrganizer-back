from sqlalchemy.orm import Session, joinedload
from sqlalchemy import or_
from typing import Optional, List
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

    def find_by_name_and_category_id(self, name: str, category_id: int) -> Optional[Tag]:
        return self.db.query(Tag).filter(Tag.name == name, Tag.category_id == category_id).first()

    def find_tags_for_user(self, user_id: int, skip: int = 0, limit: int = 100) -> List[Tag]:
        return self.db.query(Tag).options(
            joinedload(Tag.category) # Eager-load category
        ).filter(
            or_(Tag.user_id.is_(None), Tag.user_id == user_id)
        ).offset(skip).limit(limit).all()

    def create(self, tag_data: TagCreate, user_id: Optional[int] = None) -> Tag:
        db_tag = Tag(**tag_data.model_dump(exclude_unset=True))
        if user_id:
            db_tag.user_id = user_id
        self.db.add(db_tag)
        self.db.flush()
        self.db.refresh(db_tag)
        return db_tag

    def update(self, tag: Tag, tag_data: TagUpdate) -> Tag:
        update_data = tag_data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(tag, key, value)
        return tag

    def delete(self, tag: Tag) -> None:
        self.db.delete(tag)

    def find_or_create_tags_by_name(self, user_id: int, tag_names: List[str], category_id: int) -> List[Tag]:
        tags = []
        for name in tag_names:
            tag = self.find_by_name(name)
            if not tag:
                tag_create = TagCreate(name=name, category_id=category_id)
                tag = self.create(tag_create, user_id=user_id)
            tags.append(tag)
        return tags