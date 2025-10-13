# config/config.py
import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Database
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "postgresql://vizota_user:vizota_pass@db:5432/vizota_db"
    )
    
    # Server
    PORT: int = int(os.getenv("PORT", 8000))
    DEBUG: bool = os.getenv("DEBUG", "True").lower() == "true"
    
    # Security
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your-secret-key-change-this")
    
    class Config:
        env_file = ".env"

settings = Settings()