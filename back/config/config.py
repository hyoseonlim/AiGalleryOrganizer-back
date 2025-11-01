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
    SECRET_KEY: str

    # AWS S3 Settings
    AWS_PROFILE: str = os.getenv("AWS_PROFILE", "general-server-dev")
    AWS_REGION: str = os.getenv("AWS_REGION", "ap-northeast-2")
    S3_BUCKET_NAME: str = os.getenv("S3_BUCKET_NAME", "vizota-bucket")
    CLOUDFRONT_DOMAIN: str | None = os.getenv("CLOUDFRONT_DOMAIN")
    GENERAL_SERVER_URL: str = os.getenv("GENERAL_SERVER_URL", "http://localhost:8000")

    # AI Analysis Settings
    TAG_CONFIDENCE_THRESHOLD: float = float(os.getenv("TAG_CONFIDENCE_THRESHOLD", "30.0"))  # 태그 저장 최소 신뢰도 (%)

    class Config:
        env_file = ".env"
        extra = "allow"  # Allow extra environment variables

settings = Settings()