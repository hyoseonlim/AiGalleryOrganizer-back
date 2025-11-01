# AI Gallery Organizer
2025 EC & TCP & NL 해커톤 6팀 Vizota
<br><br>

## 🔧  Architecture
<img width="952" height="571" alt="image" src="https://github.com/user-attachments/assets/8d6795b3-85a9-4d8b-8451-964ff73b5bdd" />
<br><br>

### Frontend
- Flutter 3.0+ - 크로스 플랫폼 앱 → 안드로이드 / iOS / 웹 대응

### Backend
- FastAPI 0.104+
- PostgreSQL 15+ - pgvector 확장
- SQLAlchemy 2.0+ - ORM

### AI/ML
- PyTorch - 딥러닝 프레임워크
    - mobilenetv3_small_100.lamb_in1k : 입력된 이미지를 imagenet이 미리 선별한 1000개의 태그 중 정확도가 높은 태그를 출력하는 모델
    - bart-large-mnli: 위의 mobilenetv3가 출력한 태그와 미리 선별되어 가지고 있는 사용자의 대분류 태그들 간의 정확도를 보여주는 모델

### Infrastructure
- Docker - 컨테이너화
- Docker Compose - 로컬 개발 환경
- S3 & CloudFront - 이미지 처리
<br><br>

## ⚒️  ERD
<img width="1288" height="838" alt="image" src="https://github.com/user-attachments/assets/5eb67e83-318f-4a66-8a92-b02587ad3059" />





