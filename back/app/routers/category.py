from fastapi import APIRouter, Depends, status
from typing import List

from sqlalchemy.orm import Session
from app.dependencies import get_db, get_current_user # get_current_user는 인증에 사용됨
from app.models.user import User # 현재 사용자의 ID를 가져오기 위함
from app.schemas.category import CategoryCreate, CategoryUpdate, CategoryResponse
from app.services.category import CategoryService
from app.repositories.category import CategoryRepository # 의존성 주입을 위함

router = APIRouter(tags=["categories"])

# CategoryService를 가져오기 위한 의존성
def get_category_service(db: Session = Depends(get_db)) -> CategoryService:
    repository = CategoryRepository(db)
    return CategoryService(repository)

@router.post("/", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
def create_category(
    category_data: CategoryCreate,
    service: CategoryService = Depends(get_category_service),
    current_user: User = Depends(get_current_user), # 카테고리는 사용자별 또는 관리자 전용일 수 있음
):
    """새 카테고리를 생성합니다."""
    # 여기에 권한 확인을 추가할 수 있음 (예: 관리자만 카테고리 생성 가능)
    return service.create_category(category_data)

@router.get("/", response_model=List[CategoryResponse])
def get_all_categories(
    skip: int = 0,
    limit: int = 100,
    service: CategoryService = Depends(get_category_service),
    current_user: User = Depends(get_current_user), # 인증 확인
):
    """모든 카테고리 목록을 가져옵니다."""
    return service.get_categories(skip=skip, limit=limit)

@router.get("/{category_id}", response_model=CategoryResponse)
def get_category_by_id(
    category_id: int,
    service: CategoryService = Depends(get_category_service),
    current_user: User = Depends(get_current_user), # 인증 확인
):
    """ID로 단일 카테고리를 가져옵니다."""
    return service.get_category(category_id)

@router.put("/{category_id}", response_model=CategoryResponse)
def update_category(
    category_id: int,
    category_data: CategoryUpdate,
    service: CategoryService = Depends(get_category_service),
    current_user: User = Depends(get_current_user), # 인증 확인
):
    """기존 카테고리를 업데이트합니다."""
    # 여기에 권한 확인을 추가할 수 있음
    return service.update_category(category_id, category_data)

@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_category(
    category_id: int,
    service: CategoryService = Depends(get_category_service),
    current_user: User = Depends(get_current_user), # 인증 확인
):
    """카테고리를 삭제합니다."""
    # 여기에 권한 확인을 추가할 수 있음
    service.delete_category(category_id)
