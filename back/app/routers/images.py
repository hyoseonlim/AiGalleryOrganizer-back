# app/routers/images.py
from fastapi import APIRouter

router = APIRouter()

@router.get("/")
def get_images():
    """이미지 목록 조회"""
    return {"message": "Images endpoint"}

@router.post("/")
def upload_image():
    """이미지 업로드"""
    return {"message": "Image uploaded"}