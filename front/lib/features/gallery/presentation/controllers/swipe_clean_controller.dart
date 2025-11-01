import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/models/photo_models.dart';
import '../../domain/image_service.dart' as image_service;
import '../../domain/trash_service.dart' as trash_service;

enum SwipeOrder { oldest, random }

class SwipeCleanController extends ChangeNotifier {
  SwipeCleanController();

  bool _isLoading = false;
  String? _error;
  SwipeOrder _order = SwipeOrder.oldest;
  final List<ImageResponse> _images = [];
  final Map<int, ImageViewableResponse> _viewableCache = {};
  int _currentIndex = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _error;
  bool get hasImages => _currentIndex < _images.length;
  SwipeOrder get order => _order;
  int get remainingCount => max(0, _images.length - _currentIndex);

  ImageResponse? get currentImage => hasImages ? _images[_currentIndex] : null;

  Future<ImageViewableResponse?> get currentImageView async {
    final image = currentImage;
    if (image == null) return null;
    if (_viewableCache.containsKey(image.id)) {
      return _viewableCache[image.id];
    }

    final response = await image_service.getImageViewUrl(image.id);
    if (response != null) {
      _viewableCache[image.id] = response;
      return response;
    }

    _error = '이미지 URL을 불러오지 못했습니다.';
    notifyListeners();
    return null;
  }

  Future<void> loadImages() async {
    _isLoading = true;
    _error = null;
    _images.clear();
    _viewableCache.clear();
    _currentIndex = 0;
    notifyListeners();

    try {
      final images = await image_service.getMyImages();
      _images.addAll(images);
      _applyOrder();
      if (_images.isEmpty) {
        _error = null;
      }
    } catch (e) {
      _error = '이미지를 불러오지 못했습니다.';
    }

    _isLoading = false;
    notifyListeners();
  }

  void changeOrder(SwipeOrder newOrder) {
    if (_order == newOrder) return;
    _order = newOrder;
    _applyOrder();
    notifyListeners();
  }

  Future<void> keepCurrent() async {
    if (!hasImages) return;
    _advance();
  }

  Future<void> discardCurrent() async {
    final image = currentImage;
    if (image == null) return;

    final result = await trash_service.softDeleteImage(image.id);
    if (result['success'] == true) {
      _viewableCache.remove(image.id);
      _images.removeAt(_currentIndex);
      if (_currentIndex >= _images.length) {
        _currentIndex = max(0, _images.length - 1);
      }
      notifyListeners();
    } else {
      _error = (result['message'] as String?) ??
          (result['error'] as String?) ??
          '이미지를 휴지통으로 이동하지 못했습니다.';
      notifyListeners();
    }
  }

  void _applyOrder() {
    if (_order == SwipeOrder.oldest) {
      _images.sort((a, b) => a.uploadedAt.compareTo(b.uploadedAt));
    } else {
      _images.shuffle();
    }
    _currentIndex = 0;
  }

  void _advance() {
    if (!hasImages) return;
    _currentIndex = min(_currentIndex + 1, _images.length);
    notifyListeners();
  }
}
