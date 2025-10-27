# app/database.py
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://vizota_user:vizota_pass@db:5432/vizota_db"
)

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    echo=True  # 개발 시 SQL 로그 출력, 프로덕션에서는 False
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()