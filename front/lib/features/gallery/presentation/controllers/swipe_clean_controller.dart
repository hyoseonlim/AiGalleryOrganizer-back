import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/api/gallery_api_factory.dart';
import '../../data/api/endpoints/image_api.dart';
import '../../data/api/endpoints/trash_api.dart';
import '../../data/models/photo_models.dart';

enum SwipeOrder { oldest, random }

class SwipeCleanController extends ChangeNotifier {
  SwipeCleanController({ImageApi? imageApi, TrashApi? trashApi})
    : _imageApi = imageApi ?? GalleryApiFactory.instance.image,
      _trashApi = trashApi ?? GalleryApiFactory.instance.trash;

  final ImageApi _imageApi;
  final TrashApi _trashApi;

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

    final response = await _imageApi.getImageViewUrl(image.id);
    if (response.success && response.data != null) {
      _viewableCache[image.id] = response.data!;
      return response.data!;
    }
    _error = response.error ?? '이미지 URL을 불러오지 못했습니다.';
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

    final response = await _imageApi.getMyImages();
    if (response.success && response.data != null) {
      _images.addAll(response.data!);
      _applyOrder();
    } else {
      _error = response.error ?? '이미지를 불러오지 못했습니다.';
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

    final response = await _trashApi.softDeleteImage(image.id);
    if (response.success) {
      _viewableCache.remove(image.id);
      _images.removeAt(_currentIndex);
      if (_currentIndex >= _images.length) {
        _currentIndex = max(0, _images.length - 1);
      }
      notifyListeners();
    } else {
      _error = response.error ?? '이미지를 휴지통으로 이동하지 못했습니다.';
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
