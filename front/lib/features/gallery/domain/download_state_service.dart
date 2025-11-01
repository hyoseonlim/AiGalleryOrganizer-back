import 'package:flutter/foundation.dart';

/// Manages the state of file download operations
class DownloadStateService extends ChangeNotifier {
  bool _isDownloading = false;
  int _downloadCurrent = 0;
  int _downloadTotal = 0;

  bool get isDownloading => _isDownloading;
  int get downloadCurrent => _downloadCurrent;
  int get downloadTotal => _downloadTotal;

  /// Gets the current download progress as a value between 0.0 and 1.0
  double get downloadProgress {
    if (_downloadTotal == 0) return 0.0;
    return _downloadCurrent / _downloadTotal;
  }

  /// Checks if the download is complete
  bool get isDownloadComplete => _downloadCurrent >= _downloadTotal && _downloadTotal > 0;

  /// Starts a new download operation
  void startDownload() {
    _isDownloading = true;
    _downloadCurrent = 0;
    _downloadTotal = 0;
    notifyListeners();
  }

  /// Updates the download progress
  void updateProgress(int current, int total) {
    _downloadCurrent = current;
    _downloadTotal = total;
    _isDownloading = current < total;
    notifyListeners();
  }

  /// Finishes the current download operation
  void finishDownload() {
    _isDownloading = false;
    _downloadCurrent = 0;
    _downloadTotal = 0;
    notifyListeners();
  }

  /// Resets the download state to initial values
  void reset() {
    _isDownloading = false;
    _downloadCurrent = 0;
    _downloadTotal = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}