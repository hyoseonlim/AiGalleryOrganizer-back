# AI Gallery Organizer
2025 EC & TCP & NL 해커톤 6팀 Vizota
<br><br>

## 🔧  Architecture
<img width="858" height="544" alt="image" src="https://github.com/user-attachments/assets/eb71df81-14e9-433c-bc90-3f714bda26be" />
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
<img width="1197" height="645" alt="erd" src="https://github.com/user-attachments/assets/fb67aade-057e-489e-8ba1-879309896777" />




