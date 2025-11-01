import 'package:flutter/foundation.dart';

/// Manages the state of file upload operations
class UploadStateService extends ChangeNotifier {
  bool _isUploading = false;
  int _uploadCurrent = 0;
  int _uploadTotal = 0;

  bool get isUploading => _isUploading;
  int get uploadCurrent => _uploadCurrent;
  int get uploadTotal => _uploadTotal;

  /// Gets the current upload progress as a value between 0.0 and 1.0
  double get uploadProgress {
    if (_uploadTotal == 0) return 0.0;
    return _uploadCurrent / _uploadTotal;
  }

  /// Checks if the upload is complete
  bool get isUploadComplete => _uploadCurrent >= _uploadTotal && _uploadTotal > 0;

  /// Starts a new upload operation
  void startUpload() {
    _isUploading = true;
    _uploadCurrent = 0;
    _uploadTotal = 0;
    notifyListeners();
  }

  /// Updates the upload progress
  void updateProgress(int current, int total) {
    _uploadCurrent = current;
    _uploadTotal = total;
    _isUploading = current < total;
    notifyListeners();
  }

  /// Finishes the current upload operation
  void finishUpload() {
    _isUploading = false;
    _uploadCurrent = 0;
    _uploadTotal = 0;
    notifyListeners();
  }

  /// Resets the upload state to initial values
  void reset() {
    _isUploading = false;
    _uploadCurrent = 0;
    _uploadTotal = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}