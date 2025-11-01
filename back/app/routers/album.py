from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from app.dependencies import get_current_user, get_album_service
from app.models.user import User
from app.services.album import AlbumService
from app.schemas.album import AlbumCreate, AlbumUpdate, AlbumResponse, AlbumImageRequest

router = APIRouter(tags=["albums"])

@router.post("/", response_model=AlbumResponse, status_code=status.HTTP_201_CREATED)
def create_album(
    album_data: AlbumCreate,
    service: AlbumService = Depends(get_album_service),
    current_user: User = Depends(get_current_user),
):
    """
    새로운 앨범을 생성합니다.
    """
    album = service.create_album(current_user.id, album_data)
    # 앨범에 포함된 이미지 수를 계산하여 추가합니다.
    setattr(album, 'image_count', len(album.images))
    return album

@router.get("/", response_model=List[AlbumResponse])
def get_all_albums(
    service: AlbumService = Depends(get_album_service),
    current_user: User = Depends(get_current_user),
):
    """
    사용자의 모든 앨범 목록을 반환합니다.
    """
    albums = service.get_all_albums_by_user(current_user.id)
    for album in albums:
        setattr(album, 'image_count', len(album.images))
    return albums

@router.get("/{album_id}", response_model=AlbumResponse)
def get_album_by_id(
    album_id: int,
    service: AlbumService = Depends(get_album_service),
    current_user: User = Depends(get_current_user),
):
    """
    특정 앨범의 상세 정보를 반환합니다.
    """
    album = service.get_album_by_id(album_id, current_user.id)
    if not album:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Album not found")
    setattr(album, 'image_count', len(album.images))
    return album

@router.put("/{album_id}", response_model=AlbumResponse)
def update_album(
    album_id: int,
    album_data: AlbumUpdate,
    service: AlbumService = Depends(get_album_service),
    current_user: User = Depends(get_current_user),
):
    """
    앨범 정보를 업데이트합니다.
    """
    album = service.update_album(album_id, current_user.id, album_data)
    if not album:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Album not found")
    setattr(album, 'image_count', len(album.images))
    return album

@router.delete("/{album_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_album(
    album_id: int,
    service: AlbumService = Depends(get_album_service),
    current_user: User = Depends(get_current_user),
):
    """
    앨범을 삭제합니다.
    """
    if not service.delete_album(album_id, current_user.id):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Album not found")
    return

@router.post("/{album_id}/images", status_code=status.HTTP_204_NO_CONTENT)
def add_images_to_album(
    album_id: int,
    image_request: AlbumImageRequest,
    service: AlbumService = Depends(get_album_service),
    current_user: User = Depends(get_current_user),
):
    """
    앨범에 이미지를 추가합니다.
    """
    if not service.add_images_to_album(album_id, current_user.id, image_request.image_ids):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Album not found or images not found/owned by user")
    return

@router.delete("/{album_id}/images", status_code=status.HTTP_204_NO_CONTENT)
def remove_images_from_album(
    album_id: int,
    image_request: AlbumImageRequest,
    service: AlbumService = Depends(get_album_service),
    current_user: User = Depends(get_current_user),
):
    """
    앨범에서 이미지를 제거합니다.
    """
    if not service.remove_images_from_album(album_id, current_user.id, image_request.image_ids):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Album not found")
    return
