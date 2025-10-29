# back/app/models/__init__.py
from .user import User
from .image import Image
from .album import Album
from .tag import Tag
from .category import Category # Added
from .association import ImageTag, AlbumImage, SearchHistory