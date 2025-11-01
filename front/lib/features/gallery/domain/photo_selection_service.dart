import 'package:flutter/foundation.dart';

/// Manages the selection state of photos in the gallery
class PhotoSelectionService extends ChangeNotifier {
  bool _isMultiSelectMode = false;
  final Set<String> _selectedPhotos = {};

  bool get isMultiSelectMode => _isMultiSelectMode;
  Set<String> get selectedPhotos => Set.unmodifiable(_selectedPhotos);
  int get selectedCount => _selectedPhotos.length;
  bool get hasSelection => _selectedPhotos.isNotEmpty;

  /// Checks if a specific photo is selected
  bool isPhotoSelected(String photoId) {
    return _selectedPhotos.contains(photoId);
  }

  /// Toggles multi-select mode on/off
  void toggleMultiSelectMode() {
    _isMultiSelectMode = !_isMultiSelectMode;
    if (!_isMultiSelectMode) {
      _selectedPhotos.clear();
    }
    notifyListeners();
  }

  /// Enables multi-select mode
  void enableMultiSelectMode() {
    if (!_isMultiSelectMode) {
      _isMultiSelectMode = true;
      notifyListeners();
    }
  }

  /// Disables multi-select mode and clears selection
  void disableMultiSelectMode() {
    if (_isMultiSelectMode) {
      _isMultiSelectMode = false;
      _selectedPhotos.clear();
      notifyListeners();
    }
  }

  /// Toggles the selection state of a photo
  void togglePhotoSelection(String photoId) {
    if (_selectedPhotos.contains(photoId)) {
      _selectedPhotos.remove(photoId);
    } else {
      _selectedPhotos.add(photoId);
    }
    notifyListeners();
  }

  /// Selects a photo
  void selectPhoto(String photoId) {
    if (_selectedPhotos.add(photoId)) {
      notifyListeners();
    }
  }

  /// Deselects a photo
  void deselectPhoto(String photoId) {
    if (_selectedPhotos.remove(photoId)) {
      notifyListeners();
    }
  }

  /// Selects all photos from the provided list
  void selectAll(List<String> photoIds) {
    final initialCount = _selectedPhotos.length;
    _selectedPhotos.addAll(photoIds);
    if (_selectedPhotos.length != initialCount) {
      notifyListeners();
    }
  }

  /// Clears all selections
  void clearSelection() {
    if (_selectedPhotos.isNotEmpty) {
      _selectedPhotos.clear();
      notifyListeners();
    }
  }

  /// Handles photo tap based on current mode
  void onPhotoTap(String photoId) {
    if (_isMultiSelectMode) {
      togglePhotoSelection(photoId);
    }
  }

  /// Handles photo long press - enables multi-select mode and selects the photo
  void onPhotoLongPress(String photoId) {
    if (!_isMultiSelectMode) {
      enableMultiSelectMode();
      selectPhoto(photoId);
    }
  }

  @override
  void dispose() {
    _selectedPhotos.clear();
    super.dispose();
  }
}