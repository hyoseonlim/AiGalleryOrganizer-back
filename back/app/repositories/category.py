from sqlalchemy.orm import Session
from typing import Optional, List
from app.models import Category
from app.schemas.category import CategoryCreate, CategoryUpdate

class CategoryRepository:
    def __init__(self, db: Session):
        self.db = db

    def find_by_id(self, category_id: int) -> Optional[Category]:
        return self.db.query(Category).filter(Category.id == category_id).first()

    def find_by_name(self, name: str) -> Optional[Category]:
        return self.db.query(Category).filter(Category.name == name).first()

    def find_all(self, skip: int = 0, limit: int = 100) -> List[Category]:
        return self.db.query(Category).offset(skip).limit(limit).all()

    def create(self, category_data: CategoryCreate) -> Category:
        db_category = Category(**category_data.model_dump(exclude_unset=True))
        self.db.add(db_category)
        self.db.commit()
        self.db.refresh(db_category)
        return db_category

    def update(self, category: Category, category_data: CategoryUpdate) -> Category:
        update_data = category_data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(category, key, value)
        self.db.commit()
        self.db.refresh(category)
        return category

    def delete(self, category: Category) -> None:
        self.db.delete(category)
        self.db.commit()