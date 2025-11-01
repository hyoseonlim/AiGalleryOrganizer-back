import 'gallery_api_client.dart';
import 'endpoints/image_api.dart';
import 'endpoints/trash_api.dart';

/// Factory for creating gallery API instances
class GalleryApiFactory {
  GalleryApiFactory._({
    required String baseUrl,
  }) : _client = GalleryApiClient(baseUrl: baseUrl) {
    _image = ImageApi(_client);
    _trash = TrashApi(_client);
  }

  static GalleryApiFactory? _instance;

  /// Singleton instance
  static GalleryApiFactory get instance {
    _instance ??= GalleryApiFactory._(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8000',
      ),
    );
    return _instance!;
  }

  /// Initialize with custom base URL (for testing)
  static void initialize(String baseUrl) {
    _instance = GalleryApiFactory._(baseUrl: baseUrl);
  }

  final GalleryApiClient _client;
  late final ImageApi _image;
  late final TrashApi _trash;

  /// Access to image API
  ImageApi get image => _image;

  /// Access to trash API
  TrashApi get trash => _trash;

  /// Access to base client
  GalleryApiClient get client => _client;
}