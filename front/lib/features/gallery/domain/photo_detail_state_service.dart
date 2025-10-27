import 'package:flutter/foundation.dart';
import '../data/models/photo_models.dart';

/// Manages the state of photo detail view
/// This is a singleton service managed through DI
class PhotoDetailStateService extends ChangeNotifier {
  List<Photo> _photos = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  String? _error;

  List<Photo> get photos => List.unmodifiable(_photos);
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Gets the current photo being displayed
  Photo? get currentPhoto {
    if (_photos.isEmpty || _currentIndex < 0 || _currentIndex >= _photos.length) {
      return null;
    }
    return _photos[_currentIndex];
  }

  /// Checks if there's a previous photo
  bool get hasPrevious => _currentIndex > 0;

  /// Checks if there's a next photo
  bool get hasNext => _currentIndex < _photos.length - 1;

  /// Total number of photos
  int get totalPhotos => _photos.length;

  /// Initializes the photo viewer with a list of photos and starting index
  void initialize(List<Photo> photos, int startIndex) {
    _photos = photos;
    _currentIndex = startIndex.clamp(0, photos.length - 1);
    _error = null;
    notifyListeners();
  }

  /// Navigates to the next photo
  void nextPhoto() {
    if (hasNext) {
      _currentIndex++;
      notifyListeners();
    }
  }

  /// Navigates to the previous photo
  void previousPhoto() {
    if (hasPrevious) {
      _currentIndex--;
      notifyListeners();
    }
  }

  /// Jumps to a specific photo index
  void jumpToIndex(int index) {
    if (index >= 0 && index < _photos.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  /// Sets loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Sets error message
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Removes a photo from the list (after deletion)
  void removeCurrentPhoto() {
    if (_photos.isEmpty) return;

    _photos.removeAt(_currentIndex);

    // Adjust current index after removal
    if (_photos.isEmpty) {
      _currentIndex = 0;
    } else if (_currentIndex >= _photos.length) {
      _currentIndex = _photos.length - 1;
    }

    notifyListeners();
  }

  /// Updates a photo in the list
  void updatePhoto(Photo photo) {
    final index = _photos.indexWhere((p) => p.id == photo.id);
    if (index != -1) {
      _photos[index] = photo;
      notifyListeners();
    }
  }

  /// Resets the state to initial values
  void reset() {
    _photos = [];
    _currentIndex = 0;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    reset();
    super.dispose();
  }
}