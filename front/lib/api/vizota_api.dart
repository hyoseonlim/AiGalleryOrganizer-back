/// Vizota Backend API
///
/// OpenAPI 스펙 기반 전체 API 구현
///
/// 사용 예시:
/// ```dart
/// import 'package:front/api/vizota_api.dart';
///
/// // 인증
/// final authApi = AuthApiService();
/// final token = await authApi.login('username', 'password');
///
/// // 이미지
/// final imageApi = ImageApiService();
/// final images = await imageApi.getMyImages();
///
/// // 앨범
/// final albumApi = AlbumApiService();
/// final albums = await albumApi.getAllAlbums();
/// ```
library;

// Base
export 'base_api.dart';

// Services
export 'services/auth_api_service.dart';
export 'services/user_api_service.dart';
export 'services/image_api_service.dart';
export 'services/album_api_service.dart';
export 'services/tag_api_service.dart';
export 'services/similar_groups_api_service.dart';

// Models
export 'models/api_models.dart';
