from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import Base, engine
from app.models import album, association, image, tag, user, category
from app.routers import users, images, auth, category, tag, similar_group # Added tag
from app.celery_worker import celery_app
from app.initial_data import seed_data # Import seed_data

app = FastAPI(
    title="Vizota API",
    description="Team6 Vizota Backend API",
    version="1.0.0"
)

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 프로덕션에서는 특정 origin만 허용
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Health Check
@app.get("/")
def root():
    return {
        "message": "Vizota API is running",
        "version": "1.0.0",
        "status": "healthy"
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}

# 라우터 등록
app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(users.router, prefix="/api/users", tags=["users"])
app.include_router(images.router, prefix="/api/images", tags=["images"])
app.include_router(category.router, prefix="/api/categories", tags=["categories"])
app.include_router(tag.router, prefix="/api/tags", tags=["tags"])
app.include_router(similar_group.router, prefix="/api/similar-groups", tags=["similar-groups"])

# Startup/Shutdown 이벤트
@app.on_event("startup")
async def startup_event():
    print("db table creating..")
    Base.metadata.create_all(bind=engine)
    print("db table created!")
    
    # Run data seeding after tables are created
    seed_data() 
    
    print("🚀 Vizota API Server Started!")


@app.on_event("shutdown")
async def shutdown_event():
    print("👋 Vizota API Server Shutting Down...")