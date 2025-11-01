# app/routers/auth.py
from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException, status, Body
from fastapi.security import OAuth2PasswordRequestForm

from app.dependencies import get_user_service
from app.schemas.token import Token
from app.security import create_access_token, create_refresh_token, get_password_hash, verify_password, ALGORITHM
from app.services.user import UserService
from jose import jwt, JWTError
from config.config import settings

router = APIRouter(tags=["auth"])

@router.post("/login", response_model=Token)
async def login_for_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(),
    service: UserService = Depends(get_user_service),
):
    user = service.authenticate_user(email=form_data.username, password=form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=30)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    refresh_token_expires = timedelta(days=7)
    refresh_token = create_refresh_token(
        data={"sub": user.email}, expires_delta=refresh_token_expires
    )
    
    # 리프레시 토큰을 해시화하여 데이터베이스에 저장
    hashed_refresh_token = get_password_hash(refresh_token)
    service.update_refresh_token(user, hashed_refresh_token)

    return {"access_token": access_token, "token_type": "bearer", "refresh_token": refresh_token}


@router.post("/reissue", response_model=Token)
async def reissue_token(
    refresh_token: str = Body(..., embed=True),
    service: UserService = Depends(get_user_service),
):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(refresh_token, settings.SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    user = service.repository.find_by_email(email=email)
    if user is None or not user.hashed_refresh_token:
        raise credentials_exception
    
    # 저장된 해시화된 리프레시 토큰과 대조하여 검증
    if not verify_password(refresh_token, user.hashed_refresh_token):
        raise credentials_exception

    # 새로운 액세스 토큰과 리프레시 토큰 생성
    new_access_token_expires = timedelta(minutes=30)
    new_access_token = create_access_token(
        data={"sub": user.email}, expires_delta=new_access_token_expires
    )
    new_refresh_token_expires = timedelta(days=7)
    new_refresh_token = create_refresh_token(
        data={"sub": user.email}, expires_delta=new_refresh_token_expires
    )

    # 새로운 리프레시 토큰을 해시화하여 데이터베이스에 업데이트
    new_hashed_refresh_token = get_password_hash(new_refresh_token)
    service.update_refresh_token(user, new_hashed_refresh_token)

    return {
        "access_token": new_access_token,
        "token_type": "bearer",
        "refresh_token": new_refresh_token,
    }
