# 프로젝트 구조
```
back/
├── app/
│   ├── main.py              ← FastAPI 앱 진입점
│   ├── database.py          ← DB 연결
│   ├── dependencies.py      ← 의존성 (get_db 등)
│   ├── models/              ← SQLAlchemy Models (Entity)
│   ├── schemas/             ← Pydantic Models (DTO)
│   ├── routers/             ← API Endpoints (Controller)
│   ├── services/            ← Business Logic
│   └── repositories/        ← Data Access
├── config/
├── .env.example
├── .gitignore
├── docker-compose.yml
├── Dockerfile
├── pyproject.toml
└── uv.lock
```
<br>

# 실행 방법
### 서버 시작
docker-compose up

### 백그라운드 실행
docker-compose up -d

### 서버 중지
docker-compose stop

### 완전 재시작
docker-compose down && docker-compose up --build

### DB 초기화
docker-compose down -v && docker-compose up