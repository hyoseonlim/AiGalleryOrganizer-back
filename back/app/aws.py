# app/aws.py
import boto3
from config.config import settings

session = boto3.Session(profile_name=settings.AWS_PROFILE)
s3_client = session.client("s3", region_name=settings.AWS_REGION)

def get_s3_client():
    """FastAPI Dependency to get a boto3 S3 client."""
    return s3_client
