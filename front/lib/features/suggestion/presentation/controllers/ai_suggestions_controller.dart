import 'package:flutter/material.dart';
import 'package:front/features/gallery/data/models/photo_models.dart';

import '../../data/models/similar_group_models.dart';
import '../../domain/ai_suggestion_service.dart';

class AiSuggestionsController extends ChangeNotifier {
  AiSuggestionsController(this._service);

  final AiSuggestionService _service;

  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  List<SimilarGroup> _groups = [];
  final Map<int, List<ImageResponse>> _groupImages = {};
  final Map<int, Set<int>> _selectedForDeletion = {};

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  List<SimilarGroup> get groups => _groups;

  int get totalImages =>
      _groups.fold<int>(0, (sum, group) => sum + group.imageCount);

  int get removableImages =>
      _groups.fold<int>(0, (sum, group) => sum + group.removableCount);

  double get potentialSavingRatio =>
      totalImages == 0 ? 0 : removableImages / totalImages;

  Future<void> loadSuggestions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final response = await _service.getSuggestedGroups();
    if (response.success && response.data != null) {
      _groups = response.data!;
    } else {
      _errorMessage = response.error ?? 'AI 제안을 불러오지 못했습니다.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshSuggestions() async {
    _isRefreshing = true;
    notifyListeners();
    final response = await _service.regenerateSuggestions();
    if (response.success && response.data != null) {
      _groups = response.data!;
      _groupImages.clear();
      _selectedForDeletion.clear();
      _errorMessage = null;
    } else {
      _errorMessage = response.error ?? 'AI 제안을 새로 고칠 수 없습니다.';
    }
    _isRefreshing = false;
    notifyListeners();
  }

  Future<List<ImageResponse>> loadGroupImages(int groupId) async {
    if (_groupImages.containsKey(groupId)) {
      return _groupImages[groupId]!;
    }

    final response = await _service.getGroupImages(groupId);
    if (response.success && response.data != null) {
      final images = response.data!;
      _groupImages[groupId] = images;
      notifyListeners();
      return images;
    } else {
      throw Exception(response.error ?? '그룹 이미지를 불러올 수 없습니다.');
    }
  }

  List<ImageResponse>? cachedGroupImages(int groupId) {
    return _groupImages[groupId];
  }

  Set<int> selectedForDeletion(int groupId) {
    return _selectedForDeletion[groupId] ?? <int>{};
  }

  void toggleSelection(int groupId, int imageId) {
    final current = _selectedForDeletion.putIfAbsent(groupId, () => <int>{});
    if (current.contains(imageId)) {
      current.remove(imageId);
    } else {
      current.add(imageId);
    }
    notifyListeners();
  }

  Future<bool> confirmBest(int groupId) async {
    final response = await _service.confirmBest(groupId);
    if (response.success) {
      _removeGroup(groupId);
      return true;
    } else {
      _errorMessage = response.error ?? '대표 이미지만 남기기에 실패했습니다.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmSelection(int groupId) async {
    final selection = _selectedForDeletion[groupId];
    if (selection == null || selection.isEmpty) {
      _errorMessage = '삭제할 이미지를 선택해주세요.';
      notifyListeners();
      return false;
    }

    final response = await _service.confirmGroup(
      groupId: groupId,
      imageIdsToDelete: selection.toList(),
    );
    if (response.success) {
      _removeGroup(groupId);
      return true;
    } else {
      _errorMessage = response.error ?? '선택 삭제에 실패했습니다.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectGroup(int groupId) async {
    final response = await _service.rejectGroup(groupId);
    if (response.success) {
      _removeGroup(groupId);
      return true;
    } else {
      _errorMessage = response.error ?? '제안 거절에 실패했습니다.';
      notifyListeners();
      return false;
    }
  }

  void _removeGroup(int groupId) {
    _groups = _groups.where((group) => group.id != groupId).toList();
    _groupImages.remove(groupId);
    _selectedForDeletion.remove(groupId);
    notifyListeners();
  }
}
