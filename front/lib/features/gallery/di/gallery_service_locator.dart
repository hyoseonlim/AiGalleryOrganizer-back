import '../domain/photo_detail_state_service.dart';
import '../domain/photo_selection_service.dart';
import '../domain/upload_state_service.dart';
import '../domain/delete_state_service.dart';
import '../domain/download_state_service.dart';

/// Simple service locator for gallery feature services
/// Ensures singleton instances are shared across the app
class GalleryServiceLocator {
  static final GalleryServiceLocator _instance = GalleryServiceLocator._internal();

  factory GalleryServiceLocator() {
    return _instance;
  }

  GalleryServiceLocator._internal();

  // Singleton service instances
  PhotoDetailStateService? _photoDetailStateService;
  PhotoSelectionService? _photoSelectionService;
  UploadStateService? _uploadStateService;
  DeleteStateService? _deleteStateService;
  DownloadStateService? _downloadStateService;

  /// Gets or creates the PhotoDetailStateService singleton
  PhotoDetailStateService get photoDetailStateService {
    _photoDetailStateService ??= PhotoDetailStateService();
    return _photoDetailStateService!;
  }

  /// Gets or creates the PhotoSelectionService singleton
  PhotoSelectionService get photoSelectionService {
    _photoSelectionService ??= PhotoSelectionService();
    return _photoSelectionService!;
  }

  /// Gets or creates the UploadStateService singleton
  UploadStateService get uploadStateService {
    _uploadStateService ??= UploadStateService();
    return _uploadStateService!;
  }

  /// Gets or creates the DeleteStateService singleton
  DeleteStateService get deleteStateService {
    _deleteStateService ??= DeleteStateService();
    return _deleteStateService!;
  }

  /// Gets or creates the DownloadStateService singleton
  DownloadStateService get downloadStateService {
    _downloadStateService ??= DownloadStateService();
    return _downloadStateService!;
  }

  /// Disposes all services and clears the container
  void dispose() {
    _photoDetailStateService?.dispose();
    _photoSelectionService?.dispose();
    _uploadStateService?.dispose();
    _deleteStateService?.dispose();
    _downloadStateService?.dispose();

    _photoDetailStateService = null;
    _photoSelectionService = null;
    _uploadStateService = null;
    _deleteStateService = null;
    _downloadStateService = null;
  }

  /// Resets a specific service (useful for testing or logout)
  void resetService<T>() {
    if (T == PhotoDetailStateService) {
      _photoDetailStateService?.dispose();
      _photoDetailStateService = null;
    } else if (T == PhotoSelectionService) {
      _photoSelectionService?.dispose();
      _photoSelectionService = null;
    } else if (T == UploadStateService) {
      _uploadStateService?.dispose();
      _uploadStateService = null;
    } else if (T == DeleteStateService) {
      _deleteStateService?.dispose();
      _deleteStateService = null;
    } else if (T == DownloadStateService) {
      _downloadStateService?.dispose();
      _downloadStateService = null;
    }
  }
}