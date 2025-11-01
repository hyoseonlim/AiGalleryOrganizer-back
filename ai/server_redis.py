"""
Vizota AI Celery Worker
이미지 태깅 및 품질 평가를 위한 Celery Worker
Redis 메시지 큐를 감시하고 분석 후 백엔드로 결과 전송
"""

import os
os.environ["TF_USE_LEGACY_KERAS"] = "1"
import logging
import requests
import json

from celery import Celery
from typing import List, Optional, Dict, Any

import torch
from transformers import MobileViTFeatureExtractor, MobileViTForImageClassification, pipeline
from PIL import Image

import predict_one_image

# 환경 변수 로드
from dotenv import load_dotenv
load_dotenv()

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Redis 설정 (환경 변수로 설정 가능)
REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
REDIS_PORT = os.getenv('REDIS_PORT', '6379')
REDIS_DB = os.getenv('REDIS_DB', '0')
REDIS_URL = f'redis://{REDIS_HOST}:{REDIS_PORT}/{REDIS_DB}'

# Celery 앱 생성
app = Celery(
    'vizota_ai',
    broker=REDIS_URL,
    backend=REDIS_URL
)

# Celery 설정
app.conf.update(
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    timezone='Asia/Seoul',
    enable_utc=False,
    task_track_started=True,
    task_time_limit=300,  # 5분 타임아웃
    worker_prefetch_multiplier=1,
    worker_max_tasks_per_child=50,
    broker_connection_retry_on_startup=True,
)

# 디바이스 설정
if torch.cuda.is_available():
    device = torch.device('cuda')
    device_id = 0
elif torch.backends.mps.is_available():
    device = torch.device('mps')
    device_id = 0
else:
    device = torch.device('cpu')
    device_id = -1

logger.info(f"Using device: {device}")

# 전역 변수 - 모델
feature_extractor = None
model = None
classifier = None
feature_maps = {}
target_layer_name = 'dropout'

# 백엔드 API 설정 (환경변수로 설정 가능)
BACKEND_API_URL = os.getenv('BACKEND_API_URL', 'http://localhost:8000/api/images/{image_id}/analysis-results')


# Feature map hook
def get_features(name):
    def hook(model, input, output):
        if isinstance(output, tuple):
            feature_maps[name] = output[0].detach()
        else:
            feature_maps[name] = output.detach()
    return hook


# 모델 초기화 함수
def load_models():
    """Worker 시작 시 모델을 로드합니다."""
    global feature_extractor, model, classifier

    logger.info("🚀 Loading AI models...")

    try:
        # MobileViT 모델 로드
        feature_extractor = MobileViTFeatureExtractor.from_pretrained("apple/mobilevit-small")
        model = MobileViTForImageClassification.from_pretrained("apple/mobilevit-small")
        model.eval()
        model.to(device)

        # Feature extraction hook 설정
        try:
            target_layer = dict(model.named_modules())[target_layer_name]
            target_layer.register_forward_hook(get_features(target_layer_name))
            logger.info("✅ Feature Vector 추출 설정 완료")
        except KeyError:
            logger.warning("⚠️ Feature Vector 추출 설정 실패")

        # Zero-shot classification 모델 로드
        classifier = pipeline(
            "zero-shot-classification",
            model="facebook/bart-large-mnli",
            device=device_id
        )

        logger.info(f"All models loaded successfully on {device}")

    except Exception as e:
        logger.error(f"Error loading models: {e}")
        raise


# Celery Worker 시작 시 모델 로드
@app.task(bind=True)
def worker_init(self):
    """Worker 초기화 시 모델을 로드합니다."""
    load_models()
    return "Models loaded successfully"


# 백엔드로 결과 전송
def send_result_to_backend(result_data: Dict[str, Any], task_id: str = None, image_id: str = None) -> bool:
    """
    분석 결과를 백엔드 API로 전송합니다.

    Args:
        result_data: 전송할 결과 데이터
        task_id: Celery task ID (선택)

    Returns:
        bool: 전송 성공 여부
    """
    try:
        headers = {'Content-Type': 'application/json'}

        # task_id가 있으면 결과 데이터에 포함
        if task_id:
            result_data['task_id'] = task_id

        # image_id로 URL 동적 생성
        if image_id:
            api_url = BACKEND_API_URL.format(image_id=image_id)
        else:
            # image_id가 없으면 기본 URL 사용
            api_url = BACKEND_API_URL.replace('/{image_id}', '')

        logger.info(f"📤 Sending result to backend: {api_url}")
        logger.info(f"📊 Analysis Result Summary:")
        logger.info(f"   • Tag: {result_data.get('tag_name', 'N/A')} (probability: {result_data.get('probability', 0):.2f}%)")
        logger.info(f"   • Category: {result_data.get('category', 'N/A')} (probability: {result_data.get('category_probability', 0):.2f}%)")
        logger.info(f"   • Quality Score: {result_data.get('quality_score', 'N/A')}")
        logger.info(f"   • Feature Vector size: {len(result_data.get('feature_vector', []))}")
        logger.debug(f"🔍 Full result data: {json.dumps(result_data, indent=2)}")

        response = requests.post(
            api_url,
            json=result_data,
            headers=headers,
            timeout=30
        )

        response.raise_for_status()
        logger.info(f"✅ Result sent successfully. Response: {response.status_code}")
        logger.info(f"📥 Backend response: {response.text[:200]}{'...' if len(response.text) > 200 else ''}")
        return True

    except requests.exceptions.RequestException as e:
        logger.error(f"❌ Failed to send result to backend: {e}")
        return False


# 이미지 분석 Celery Task
@app.task(bind=True, name='app.tasks.analyze_image_task')
def analyze_image_task(
    self,
    image_url: str,
    candidate_labels: Optional[List[str]] = ['Landscape', 'Animal', 'City', 'People', 'Food'],
    image_id: Optional[str] = None,
    user_id: Optional[str] = None
) -> Dict[str, Any]:
    """
    Redis 큐로부터 이미지 분석 작업을 수신하고 처리합니다.

    Args:
        image_url: 분석할 이미지의 S3 URL
        candidate_labels: (선택) 계층적 분류를 위한 후보 레이블 목록
        image_id: (선택) 이미지 식별자
        user_id: (선택) 사용자 식별자

    Returns:
        Dict: 분석 결과
            - tag_name: 이미지 분류명
            - probability: 분류 확률 (%)
            - category: 추천 상위 태그
            - category_probability: 추천 태그 확률 (%)
            - quality_score: 이미지 품질 점수 (0-1)
            - feature_vector: 추출된 feature vector (1x640, list type)
    """
    try:
        # 모델이 로드되지 않았다면 로드
        if model is None or classifier is None:
            logger.info("Models not loaded. Loading now...")
            load_models()

        logger.info(f"[Task {self.request.id}] Analyzing image: {image_url}")
        if image_id:
            logger.info(f"Image ID: {image_id}")
        if user_id:
            logger.info(f"User ID: {user_id}")

        # 이미지 다운로드
        try:
            response = requests.get(image_url, verify=False, timeout=30)
            response.raise_for_status()
            from io import BytesIO
            image = Image.open(BytesIO(response.content)).convert('RGB')
            logger.info(f"✅ Image downloaded successfully: {len(response.content)} bytes")
        except Exception as e:
            error_msg = f"Failed to load image: {str(e)}"
            logger.error(error_msg)
            raise Exception(error_msg)

        # 이미지 전처리 및 태깅
        inputs = feature_extractor(images=image, return_tensors="pt").to(device)

        with torch.no_grad():
            # 태그 예측
            outputs = model(**inputs)
            logits = outputs.logits

            # 품질 점수 계산
            try:
                quality_score = predict_one_image.main(image)
                if torch.is_tensor(quality_score):
                    quality_score = quality_score.item()
            except Exception as e:
                logger.warning(f"Quality score calculation failed: {e}")
                quality_score = None

        # Top prediction 추출 (K값 변경을 통해 추천 태그 개수 변경 가능)
        top_probability, top_class_index = torch.topk(logits.softmax(dim=1) * 100, k=1)

        class_name = model.config.id2label[top_class_index[0][0].item()]
        # comma로 구분된 경우 첫 번째 태그만 추출
        class_name = class_name.split(',')[0].strip()
        probability = top_probability[0][0].item()

        # Feature vector 추출
        feature_vector = None
        if target_layer_name in feature_maps:
            extracted_features = feature_maps[target_layer_name]
            feature_vector = extracted_features.cpu().numpy().tolist()
            logger.info(f"Feature vector size: {extracted_features.size()}")

        # 계층적 분류
        recommended_high_tag = None
        recommended_high_tag_prob = None

        if candidate_labels and len(candidate_labels) > 0:
            try:
                hierar = classifier(class_name, candidate_labels, multi_label=True)
                recommended_high_tag = hierar['labels'][0]
                recommended_high_tag_prob = hierar['scores'][0] * 100
                logger.info(f"Recommended tag: {recommended_high_tag} ({recommended_high_tag_prob:.2f}%)")
            except Exception as e:
                logger.warning(f"Hierarchical classification failed: {e}")

        # 백엔드 API 형식에 맞춰 결과 생성 (ImageAnalysisResult 스키마)
        result = {
            'tag_name': class_name,
            'probability': round(probability, 2),  # 태그 예측 확률 (%)
            'category': recommended_high_tag if recommended_high_tag else 'Unknown',
            'category_probability': round(recommended_high_tag_prob, 2) if recommended_high_tag_prob else None,
            'quality_score': round(quality_score, 4) if quality_score else None,
            'feature_vector': feature_vector[0] if feature_vector else []  # 첫 번째 배치의 임베딩
        }

        # 추가 메타데이터 (로깅용)
        result_metadata = {
            'probability_percent': round(probability, 2),
            'category_probability': round(recommended_high_tag_prob, 2) if recommended_high_tag_prob else None,
            'quality_score': round(quality_score, 4) if quality_score else None,
            'image_url': image_url,
        }

        if image_id:
            result_metadata['image_id'] = image_id
        if user_id:
            result_metadata['user_id'] = user_id

        logger.info(f"[Task {self.request.id}] Analysis complete: {class_name} ({probability:.2f}%)")

        # 백엔드로 결과 전송
        send_success = send_result_to_backend(result, task_id=self.request.id, image_id=image_id)
        result['sent_to_backend'] = send_success

        return result

    except Exception as e:
        logger.error(f"[Task {self.request.id}] Error analyzing image: {e}")

        # 에러 정보를 백엔드로 전송 (ImageAnalysisResult 스키마 형식)
        error_result = {
            'tag_name': 'error',
            'probability': 0.0,
            'category': 'Unknown',
            'category_probability': None,
            'quality_score': None,
            'feature_vector': []
        }

        send_result_to_backend(error_result, task_id=self.request.id, image_id=image_id)

        raise


if __name__ == "__main__":
    # Worker 실행 방법:
    # celery -A server worker --loglevel=info --concurrency=1
    logger.info("Starting Vizota AI Celery Worker...")
    logger.info("Run with: celery -A server worker --loglevel=info --concurrency=1")
