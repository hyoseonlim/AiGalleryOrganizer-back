import 'gallery_api_client.dart';
import 'endpoints/upload_api.dart';
import 'endpoints/image_api.dart';
import 'endpoints/trash_api.dart';
import 'endpoints/download_api.dart';
import 'endpoints/tag_api.dart';

/// Gallery API 팩토리
/// 모든 API 엔드포인트에 대한 접근을 제공
class GalleryApiFactory {
  final GalleryApiClient _client;

  late final UploadApi upload;
  late final ImageApi image;
  late final TrashApi trash;
  late final DownloadApi download;
  late final TagApi tag;

  GalleryApiFactory({String baseUrl = 'http://localhost:8000'})
      : _client = GalleryApiClient(baseUrl: baseUrl) {
    upload = UploadApi(_client);
    image = ImageApi(_client);
    trash = TrashApi(_client);
    download = DownloadApi(_client);
    // tag = TagApi(_client);
  }

  /// 싱글톤 인스턴스
  static final GalleryApiFactory _instance = GalleryApiFactory();

  static GalleryApiFactory get instance => _instance;

  /// 클라이언트 종료
  void dispose() {
    _client.dispose();
  }
}
