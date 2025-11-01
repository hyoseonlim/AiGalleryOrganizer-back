import 'package:flutter/material.dart';
import 'package:front/features/gallery/domain/trash_service.dart';
import 'package:front/features/gallery/data/models/photo_models.dart';
import 'package:front/features/gallery/data/repositories/local_photo_repository.dart';
import 'dart:io';
import 'dart:developer' as developer;

class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  List<Photo> _trashedPhotos = [];
  final Set<String> _selectedPhotos = {};
  bool _isLoading = true;
  bool _isMultiSelectMode = false;
  final _localRepo = LocalPhotoRepository();

  @override
  void initState() {
    super.initState();
    _loadTrashedPhotos();
  }

  /// Load trashed photos from backend
  Future<void> _loadTrashedPhotos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await getTrashedImages();

      if (result['success'] == true) {
        final trashedImages = result['images'] as List<ImageResponse>? ?? [];

        // Convert to Photo objects
        final photos = <Photo>[];
        for (final imageResponse in trashedImages) {
          // Get local thumbnail if available
          final thumbnailFile = await _localRepo.getThumbnail(imageResponse.id.toString());

          photos.add(imageResponse.toPhoto(
            localThumbnailPath: thumbnailFile?.path,
          ));
        }

        setState(() {
          _trashedPhotos = photos;
          _isLoading = false;
        });
      } else {
        throw Exception(result['error'] ?? '휴지통 조회 실패');
      }
    } catch (e) {
      developer.log('휴지통 조회 오류: $e', name: 'TrashPage');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('휴지통 조회 중 오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Toggle multi-select mode
  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedPhotos.clear();
      }
    });
  }

  /// Handle photo tap
  void _onPhotoTap(String photoId) {
    if (_isMultiSelectMode) {
      setState(() {
        if (_selectedPhotos.contains(photoId)) {
          _selectedPhotos.remove(photoId);
        } else {
          _selectedPhotos.add(photoId);
        }
      });
    }
  }

  /// Handle photo long press
  void _onPhotoLongPress(String photoId) {
    if (!_isMultiSelectMode) {
      setState(() {
        _isMultiSelectMode = true;
        _selectedPhotos.add(photoId);
      });
    }
  }

  /// Restore selected photos
  Future<void> _handleRestoreSelected() async {
    if (_selectedPhotos.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('복원'),
        content: Text('선택한 ${_selectedPhotos.length}개의 사진을 복원하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
            child: const Text('복원'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // Convert photo IDs to integers
      final imageIds = _selectedPhotos
          .map((id) => int.tryParse(id))
          .where((id) => id != null)
          .cast<int>()
          .toList();

      if (imageIds.isEmpty) {
        throw Exception('유효한 사진 ID가 없습니다');
      }

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${imageIds.length}개의 사진을 복원하는 중...'),
            duration: const Duration(seconds: 30),
          ),
        );
      }

      // Restore photos
      int successCount = 0;
      int failedCount = 0;

      for (final imageId in imageIds) {
        final result = await restoreImage(imageId);
        if (result['success'] == true) {
          successCount++;
        } else {
          failedCount++;
        }
      }

      // Clear selection
      setState(() {
        _isMultiSelectMode = false;
        _selectedPhotos.clear();
      });

      // Hide loading
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      // Reload trash
      await _loadTrashedPhotos();

      // Show result
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failedCount > 0
                  ? '$successCount개 복원 완료, $failedCount개 실패'
                  : '$successCount개의 사진이 복원되었습니다',
            ),
            backgroundColor: failedCount > 0 ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isMultiSelectMode = false;
        _selectedPhotos.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('복원 중 오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Permanently delete selected photos
  Future<void> _handlePermanentDeleteSelected() async {
    if (_selectedPhotos.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('영구 삭제'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('선택한 ${_selectedPhotos.length}개의 사진을 영구적으로 삭제하시겠습니까?'),
            const SizedBox(height: 8),
            const Text(
              '이 작업은 되돌릴 수 없습니다.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('영구 삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // Convert photo IDs to integers
      final imageIds = _selectedPhotos
          .map((id) => int.tryParse(id))
          .where((id) => id != null)
          .cast<int>()
          .toList();

      if (imageIds.isEmpty) {
        throw Exception('유효한 사진 ID가 없습니다');
      }

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${imageIds.length}개의 사진을 영구 삭제하는 중...'),
            duration: const Duration(seconds: 30),
          ),
        );
      }

      // Delete photos permanently
      int successCount = 0;
      int failedCount = 0;

      for (final imageId in imageIds) {
        final result = await permanentlyDeleteImage(imageId);
        if (result['success'] == true) {
          successCount++;
          // Delete local files
          await _localRepo.deletePhoto(imageId.toString());
        } else {
          failedCount++;
        }
      }

      // Clear selection
      setState(() {
        _isMultiSelectMode = false;
        _selectedPhotos.clear();
      });

      // Hide loading
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      // Reload trash
      await _loadTrashedPhotos();

      // Show result
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failedCount > 0
                  ? '$successCount개 삭제 완료, $failedCount개 실패'
                  : '$successCount개의 사진이 영구 삭제되었습니다',
            ),
            backgroundColor: failedCount > 0 ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isMultiSelectMode = false;
        _selectedPhotos.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 중 오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Empty trash (delete all)
  Future<void> _handleEmptyTrash() async {
    if (_trashedPhotos.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('휴지통 비우기'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('휴지통의 모든 사진(${_trashedPhotos.length}개)을 영구적으로 삭제하시겠습니까?'),
            const SizedBox(height: 8),
            const Text(
              '이 작업은 되돌릴 수 없습니다.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('모두 삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('휴지통을 비우는 중...'),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Empty trash
      final result = await emptyTrash();

      // Hide loading
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      if (result['success'] == true) {
        // Delete all local files
        for (final photo in _trashedPhotos) {
          await _localRepo.deletePhoto(photo.id);
        }

        // Reload trash
        await _loadTrashedPhotos();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('휴지통이 비워졌습니다'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result['error'] ?? '휴지통 비우기 실패');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('휴지통 비우기 중 오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trashedPhotos.isEmpty
              ? _buildEmptyState()
              : _buildPhotoGrid(),
    );
  }

  AppBar _buildAppBar() {
    if (_isMultiSelectMode) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _toggleMultiSelectMode,
        ),
        title: Text('${_selectedPhotos.length}개 선택'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _handleRestoreSelected,
            tooltip: '복원',
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _handlePermanentDeleteSelected,
            tooltip: '영구 삭제',
          ),
        ],
      );
    }

    return AppBar(
      title: const Text('휴지통'),
      actions: [
        if (_trashedPhotos.isNotEmpty)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'select') {
                _toggleMultiSelectMode();
              } else if (value == 'empty') {
                _handleEmptyTrash();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'select',
                child: Text('선택'),
              ),
              const PopupMenuItem<String>(
                value: 'empty',
                child: Text(
                  '휴지통 비우기',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '휴지통이 비어있습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '삭제된 사진이 여기에 표시됩니다',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2.0,
        mainAxisSpacing: 2.0,
      ),
      itemCount: _trashedPhotos.length,
      itemBuilder: (context, index) {
        final photo = _trashedPhotos[index];
        final isSelected = _selectedPhotos.contains(photo.id);
        return _PhotoItem(
          photo: photo,
          localRepo: _localRepo,
          isSelected: isSelected,
          isMultiSelectMode: _isMultiSelectMode,
          onTap: () => _onPhotoTap(photo.id),
          onLongPress: () => _onPhotoLongPress(photo.id),
        );
      },
    );
  }
}

class _PhotoItem extends StatelessWidget {
  final Photo photo;
  final LocalPhotoRepository localRepo;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PhotoItem({
    required this.photo,
    required this.localRepo,
    required this.isSelected,
    required this.isMultiSelectMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Display thumbnail
          FutureBuilder<File?>(
            future: localRepo.getThumbnail(photo.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              } else if (snapshot.hasData && snapshot.data != null) {
                return Image.file(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    );
                  },
                );
              } else {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.image, color: Colors.grey),
                  ),
                );
              }
            },
          ),
          // Trash overlay
          Container(
            color: Colors.black.withValues(alpha: 0.3),
          ),
          // Trash icon indicator
          if (!isMultiSelectMode)
            const Positioned(
              bottom: 4,
              right: 4,
              child: Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
          // Multi-select checkbox
          if (isMultiSelectMode)
            Positioned(
              top: 4,
              right: 4,
              child: Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? Colors.blue : Colors.white70,
              ),
            ),
          // Selection overlay
          if (isSelected)
            Container(
              color: Colors.blue.withValues(alpha: 0.3),
            ),
        ],
      ),
    );
  }
}
