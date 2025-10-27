import 'package:flutter/foundation.dart';

/// Manages the state of trash operations (soft delete, restore, permanent delete)
class TrashStateService extends ChangeNotifier {
  bool _isDeleting = false;
  int _deleteCurrent = 0;
  int _deleteTotal = 0;

  bool get isDeleting => _isDeleting;
  int get deleteCurrent => _deleteCurrent;
  int get deleteTotal => _deleteTotal;

  /// Gets the current delete progress as a value between 0.0 and 1.0
  double get deleteProgress {
    if (_deleteTotal == 0) return 0.0;
    return _deleteCurrent / _deleteTotal;
  }

  /// Checks if the delete is complete
  bool get isDeleteComplete => _deleteCurrent >= _deleteTotal && _deleteTotal > 0;

  /// Starts a new delete operation
  void startDelete() {
    _isDeleting = true;
    _deleteCurrent = 0;
    _deleteTotal = 0;
    notifyListeners();
  }

  /// Updates the delete progress
  void updateProgress(int current, int total) {
    _deleteCurrent = current;
    _deleteTotal = total;
    _isDeleting = current < total;
    notifyListeners();
  }

  /// Finishes the current delete operation
  void finishDelete() {
    _isDeleting = false;
    _deleteCurrent = 0;
    _deleteTotal = 0;
    notifyListeners();
  }

  /// Resets the delete state to initial values
  void reset() {
    _isDeleting = false;
    _deleteCurrent = 0;
    _deleteTotal = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}