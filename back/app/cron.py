# app/cron.py
import logging
from datetime import datetime, timedelta, timezone
from sqlalchemy.orm import Session
from botocore.exceptions import ClientError

from app.database import SessionLocal
from app.models.image import Image
from app.aws import get_s3_client
from config.config import settings

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def permanently_delete_old_trashed_images():
    """
    Permanently deletes images that were soft-deleted more than 30 days ago.
    This function is intended to be run as a cron job.
    """
    logger.info("Starting job: permanently delete old trashed images.")
    db: Session = SessionLocal()
    s3_client = get_s3_client()
    
    if not settings.S3_BUCKET_NAME:
        logger.error("S3_BUCKET_NAME is not configured. Aborting job.")
        return

    try:
        cutoff_date = datetime.now(timezone.utc) - timedelta(days=30)
        
        old_trashed_images = db.query(Image).filter(
            Image.deleted_at.isnot(None),
            Image.deleted_at < cutoff_date
        ).all()

        if not old_trashed_images:
            logger.info("No old trashed images to delete.")
            return

        logger.info(f"Found {len(old_trashed_images)} old trashed images to delete.")

        for image in old_trashed_images:
            logger.info(f"Processing image ID: {image.id}, URL: {image.url}")
            try:
                # 1. Delete from S3
                s3_client.delete_object(Bucket=settings.S3_BUCKET_NAME, Key=image.url)
                logger.info(f"Successfully deleted image {image.id} from S3.")

                # 2. Delete from DB
                db.delete(image)
                db.commit()
                logger.info(f"Successfully deleted image {image.id} from database.")

            except ClientError as e:
                logger.error(f"Error deleting image {image.id} from S3: {e}")
                # If S3 deletion fails, we might not want to delete from DB.
                # Rolling back the commit for this image.
                db.rollback()
            except Exception as e:
                logger.error(f"An unexpected error occurred while processing image {image.id}: {e}")
                db.rollback()

    finally:
        db.close()
        logger.info("Finished job: permanently delete old trashed images.")

if __name__ == "__main__":
    permanently_delete_old_trashed_images()
