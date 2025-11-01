from app.celery_worker import celery_app
import httpx
from app.schemas.image import ImageAnalysisResult
from config.config import settings
import logging

logger = logging.getLogger(__name__)

@celery_app.task
def analyze_image_task(image_id: int, image_url: str):
    logger.info(f"Starting analysis for image ID: {image_id}, URL: {image_url}")
    try:
        # TODO: Replace with actual AI server call to get analysis results
        # For now, simulate a delay and dummy response
        import time
        time.sleep(5) # Simulate AI processing time

        # Dummy analysis results
        # These should come from the actual AI server response
        dummy_tag = "nature"
        dummy_tag_category = "landscape"
        dummy_score = 0.95
        dummy_ai_embedding = [0.1] * 640 # 1x640 vector

        # Construct the payload for the general server's API
        analysis_results_payload = ImageAnalysisResult(
            tag=dummy_tag,
            tag_category=dummy_tag_category,
            score=dummy_score,
            ai_embedding=dummy_ai_embedding
        )

        # General server's API endpoint to receive analysis results
        # This URL should be accessible from where the Celery worker runs
        general_server_api_url = f"{settings.GENERAL_SERVER_URL}/images/{image_id}/analysis-results"

        logger.info(f"Sending analysis results to general server: {general_server_api_url}")

        # Make the HTTP POST request to the general server
        response = httpx.post(
            general_server_api_url,
            json=analysis_results_payload.model_dump() # Use model_dump() for Pydantic v2
        )
        response.raise_for_status() # Raise an exception for bad status codes (4xx or 5xx)

        logger.info(f"Analysis results for image ID {image_id} successfully sent to general server.")
        return {"image_id": image_id, "status": "completed"}

    except httpx.RequestError as e:
        logger.error(f"HTTP request failed for image ID {image_id}: {e}")
        raise
    except httpx.HTTPStatusError as e:
        logger.error(f"HTTP status error for image ID {image_id}: {e.response.status_code} - {e.response.text}")
        raise
    except Exception as e:
        logger.error(f"Error analyzing or sending results for image ID {image_id}: {e}")
        raise