# app/dependencies.py
from fastapi import Depends
from sqlalchemy.orm import Session
from app.database import get_db

# 여기에 공통 의존성 추가 (인증, 권한 등)