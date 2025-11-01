import 'package:flutter/foundation.dart';
import '../data/models/photo_models.dart';

/// Manages the state of file upload operations
class UploadStateService extends ChangeNotifier {
  bool _isUploading = false;
  int _uploadCurrent = 0;
  int _uploadTotal = 0;

  // 각 이미지의 세부 진행 상황 추적
  final Map<String, ImageUploadProgress> _imageProgressMap = {};

  // 완료된 이미지 목록 (최근 10개만 유지)
  final List<ImageUploadProgress> _completedImages = [];
  static const int _maxCompletedImages = 10;

  bool get isUploading => _isUploading;
  int get uploadCurrent => _uploadCurrent;
  int get uploadTotal => _uploadTotal;

  /// 현재 진행 중인 이미지 목록
  List<ImageUploadProgress> get activeUploads =>
      _imageProgressMap.values.where((p) => !p.isCompleted).toList();

  /// 완료된 이미지 목록
  List<ImageUploadProgress> get completedUploads =>
      List.unmodifiable(_completedImages);

  /// 전체 이미지 목록 (진행 중 + 완료)
  List<ImageUploadProgress> get allUploads {
    final active = activeUploads;
    return [...active, ..._completedImages];
  }

  /// Gets the current upload progress as a value between 0.0 and 1.0
  double get uploadProgress {
    if (_uploadTotal == 0) return 0.0;
    return _uploadCurrent / _uploadTotal;
  }

  /// 전체 업로드의 평균 진행률 (0.0 ~ 1.0)
  double get overallProgress {
    if (_imageProgressMap.isEmpty) return 0.0;

    final totalProgress = _imageProgressMap.values.fold<double>(
      0.0,
      (sum, progress) => sum + progress.progress,
    );

    return totalProgress / _imageProgressMap.length;
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

  /// 새 이미지 업로드 시작
  void addImageUpload(String photoId, String fileName) {
    _imageProgressMap[photoId] = ImageUploadProgress.initial(
      photoId: photoId,
      fileName: fileName,
    );
    notifyListeners();
  }

  /// 특정 이미지의 단계 완료 표시
  void completeImageStep(String photoId, ImageUploadStep step) {
    final progress = _imageProgressMap[photoId];
    if (progress != null) {
      _imageProgressMap[photoId] = progress.completeStep(step);

      // 모든 단계가 완료되면 완료 목록으로 이동
      if (_imageProgressMap[photoId]!.isCompleted) {
        _moveToCompleted(photoId);
      }

      notifyListeners();
    }
  }

  /// 특정 이미지의 단계 실패 표시
  void failImageStep(String photoId, ImageUploadStep step, String error) {
    final progress = _imageProgressMap[photoId];
    if (progress != null) {
      _imageProgressMap[photoId] = progress.failStep(step, error);
      print('[UploadStateService] 실패 표시: photoId=$photoId, step=$step, error=$error');
      print('[UploadStateService] activeUploads 개수: ${activeUploads.length}, allUploads 개수: ${allUploads.length}');
      notifyListeners();
    } else {
      print('[UploadStateService] 경고: photoId=$photoId를 _imageProgressMap에서 찾을 수 없습니다');
    }
  }

  /// 실패한 이미지 재시도
  void retryImage(String photoId) {
    final progress = _imageProgressMap[photoId];
    if (progress != null && progress.isFailed) {
      _imageProgressMap[photoId] = progress.resetFailure();
      notifyListeners();
    }
  }

  /// 완료된 이미지를 완료 목록으로 이동
  void _moveToCompleted(String photoId) {
    final progress = _imageProgressMap.remove(photoId);
    if (progress != null) {
      _completedImages.insert(0, progress);

      // 최대 개수 유지
      if (_completedImages.length > _maxCompletedImages) {
        _completedImages.removeRange(_maxCompletedImages, _completedImages.length);
      }
    }
  }

  /// 특정 이미지의 진행 상황 조회
  ImageUploadProgress? getImageProgress(String photoId) {
    return _imageProgressMap[photoId];
  }

  /// Finishes the current upload operation
  void finishUpload() {
    _isUploading = false;
    _uploadCurrent = 0;
    _uploadTotal = 0;

    // 성공한 이미지만 완료 처리, 실패한 이미지는 activeUploads에 남겨둠
    final remainingIds = _imageProgressMap.keys.toList();
    for (final photoId in remainingIds) {
      final progress = _imageProgressMap[photoId];
      if (progress != null && !progress.isFailed && progress.isCompleted) {
        _moveToCompleted(photoId);
      }
    }

    print('[UploadStateService] finishUpload 완료: activeUploads=${activeUploads.length}, completedUploads=${completedUploads.length}');
    notifyListeners();
  }

  /// Resets the upload state to initial values
  void reset() {
    _isUploading = false;
    _uploadCurrent = 0;
    _uploadTotal = 0;
    _imageProgressMap.clear();
    _completedImages.clear();
    notifyListeners();
  }

  /// 완료된 목록 초기화
  void clearCompleted() {
    _completedImages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}