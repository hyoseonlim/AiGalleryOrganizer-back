"""
Vizota AI FastAPI Server
이미지 태깅 및 품질 평가를 위한 API 서버
"""

import os
os.environ["TF_USE_LEGACY_KERAS"] = "1"

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, HttpUrl
from typing import List, Optional
import torch
from transformers import MobileViTFeatureExtractor, MobileViTForImageClassification, pipeline
from PIL import Image
from urllib.request import urlopen
import predict_one_image
import logging

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# FastAPI 앱 생성
app = FastAPI(
    title="Vizota AI API",
    description="Image Tagging and Quality Assessment API",
    version="1.0.0"
)

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
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

# 전역 변수 - 모델들
feature_extractor = None
model = None
classifier = None
feature_maps = {}
target_layer_name = 'dropout'

# Response Models
class ImageAnalysisResponse(BaseModel):
    tag_name: str
    probability: float
    category: Optional[str] = None
    category_probability: Optional[float] = None
    quality_score: Optional[float] = None
    feature_vector: Optional[List[List[float]]] = None

class HealthResponse(BaseModel):
    status: str
    device: str
    models_loaded: bool

# Feature extraction hook
def get_features(name):
    def hook(model, input, output):
        if isinstance(output, tuple):
            feature_maps[name] = output[0].detach()
        else:
            feature_maps[name] = output.detach()
    return hook

# 모델 초기화
@app.on_event("startup")
async def load_models():
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
        
        logger.info(f"✅ All models loaded successfully on {device}")
        
    except Exception as e:
        logger.error(f"❌ Error loading models: {e}")
        raise

@app.on_event("shutdown")
async def shutdown_event():
    logger.info("👋 Shutting down Vizota AI API Server...")

# Health Check
@app.get("/", response_model=HealthResponse)
async def root():
    return {
        "status": "healthy",
        "device": str(device),
        "models_loaded": model is not None and classifier is not None
    }

@app.get("/health", response_model=HealthResponse)
async def health_check():
    return {
        "status": "healthy",
        "device": str(device),
        "models_loaded": model is not None and classifier is not None
    }

# 이미지 분석 엔드포인트
@app.get("/api/analyze-image", response_model=ImageAnalysisResponse)
async def analyze_image(
    image_url: str = Query(..., description="S3 image URL to analyze"),
    candidate_labels: Optional[List[str]] = Query(
        None,
        description="Candidate labels for hierarchical classification (e.g., album names)"
    )
):
    """
    S3 이미지 URL을 받아서 태그, 품질 점수, 추천 상위 태그를 반환합니다.
    
    - **image_url**: 분석할 이미지의 S3 URL
    - **candidate_labels**: (선택) 계층적 분류를 위한 후보 레이블 목록 (앨범 이름 등)
    
    Returns:
        - tag_name: 이미지 분류명
        - probability: 분류 확률 (%)
        - category: 추천 상위 태그 (candidate_labels 제공 시)
        - category_probability: 추천 태그 확률 (%)
        - quality_score: 이미지 품질 점수 (0-1)
        - feature_vector: 추출된 feature vector (2D array)
    """
    try:
        # 모델 로드 확인
        if model is None or classifier is None:
            raise HTTPException(status_code=503, detail="Models not loaded yet")
        
        logger.info(f"Analyzing image: {image_url}")
        
        # 이미지 다운로드 (한 번만)
        try:
            image = Image.open(urlopen(image_url)).convert('RGB')
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Failed to load image: {str(e)}")
        
        # 이미지 전처리 및 태깅
        inputs = feature_extractor(images=image, return_tensors="pt").to(device)
        
        with torch.no_grad():
            # 태그 예측
            outputs = model(**inputs)
            logits = outputs.logits
            
            # 품질 점수 계산 (PIL Image 객체 전달)
            try:
                quality_score = predict_one_image.main(image)
                # tensor를 float로 변환
                if torch.is_tensor(quality_score):
                    quality_score = quality_score.item()
            except Exception as e:
                logger.warning(f"Quality score calculation failed: {e}")
                quality_score = None
        
        # Top prediction 추출
        top_probability, top_class_index = torch.topk(logits.softmax(dim=1) * 100, k=1)
        
        class_name = model.config.id2label[top_class_index[0][0].item()]
        probability = top_probability[0][0].item()
        
        # Feature vector 추출
        feature_vector = None
        if target_layer_name in feature_maps:
            extracted_features = feature_maps[target_layer_name]
            # tensor를 list로 변환 (JSON 직렬화 가능하도록)
            feature_vector = extracted_features.cpu().numpy().tolist()
            logger.info(f"Feature vector size: {extracted_features.size()}")
        
        # 계층적 분류 (candidate_labels가 제공된 경우)
        recommended_tag = None
        recommended_tag_prob = None
        
        if candidate_labels and len(candidate_labels) > 0:
            try:
                hierar = classifier(class_name, candidate_labels, multi_label=True)
                recommended_tag = hierar['labels'][0]
                recommended_tag_prob = hierar['scores'][0] * 100
                logger.info(f"Recommended tag: {recommended_tag} ({recommended_tag_prob:.2f}%)")
            except Exception as e:
                logger.warning(f"Hierarchical classification failed: {e}")
        
        response = ImageAnalysisResponse(
            tag_name=class_name,
            probability=round(probability, 2),
            category=recommended_tag,
            category_probability=round(recommended_tag_prob, 2) if recommended_tag_prob else None,
            quality_score=round(quality_score, 4) if quality_score else None,
            feature_vector=feature_vector
        )
        
        logger.info(f"Analysis complete: {class_name} ({probability:.2f}%)")
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error analyzing image: {e}")
        raise HTTPException(status_code=500, detail=f"Error processing image: {str(e)}")

# 테스트 엔드포인트
@app.get("/api/test")
async def test():
    """
    테스트용 엔드포인트 - 샘플 이미지로 분석 테스트
    """
    test_url = "https://d206helh22e0a3.cloudfront.net/images/brow/combo/combo.png"
    test_labels = ["travel", "food", "landscape", "portrait"]
    
    return await analyze_image(image_url=test_url, candidate_labels=test_labels)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001, log_level="info")
