import 'package:flutter/material.dart';
import 'package:front/features/gallery/domain/upload_service.dart';
import 'package:front/features/gallery/domain/upload_state_service.dart';
import 'package:front/features/gallery/domain/photo_selection_service.dart';
import 'package:front/features/gallery/data/models/photo_models.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  // Mock data for photos, grouped by date
  final Map<String, int> _photoSections = {
    '2025년 1월 15일': 3,
    '2025년 1월 14일': 6,
    '2025년 1월 12일': 5,
  };

  // Domain services
  late final UploadStateService _uploadStateService;
  late final PhotoSelectionService _photoSelectionService;

  @override
  void initState() {
    super.initState();
    _uploadStateService = UploadStateService();
    _photoSelectionService = PhotoSelectionService();

    // Listen to service changes and rebuild UI
    _uploadStateService.addListener(_onUploadStateChanged);
    _photoSelectionService.addListener(_onSelectionStateChanged);
  }

  @override
  void dispose() {
    _uploadStateService.removeListener(_onUploadStateChanged);
    _photoSelectionService.removeListener(_onSelectionStateChanged);
    _uploadStateService.dispose();
    _photoSelectionService.dispose();
    super.dispose();
  }

  void _onUploadStateChanged() {
    setState(() {});
  }

  void _onSelectionStateChanged() {
    setState(() {});
  }

  Future<void> _handlePickFile() async {
    _uploadStateService.startUpload();
    try {
      final result = await pickFile(
        onProgress: (current, total) {
          _uploadStateService.updateProgress(current, total);
        },
      );

      _uploadStateService.finishUpload();

      final uploadResult = UploadResult.fromMap(result);
      if (uploadResult.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${uploadResult.successCount}/${uploadResult.totalFiles} 파일 업로드 완료'),
          ),
        );
      }
    } catch (e) {
      _uploadStateService.finishUpload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('업로드 중 오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handlePickFolder() async {
    _uploadStateService.startUpload();
    try {
      final result = await pickFolder(
        onProgress: (current, total) {
          _uploadStateService.updateProgress(current, total);
        },
      );

      _uploadStateService.finishUpload();

      final uploadResult = UploadResult.fromMap(result);
      if (uploadResult.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${uploadResult.successCount}/${uploadResult.totalFiles} 파일 업로드 완료'),
          ),
        );
      }
    } catch (e) {
      _uploadStateService.finishUpload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('업로드 중 오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleOpenGallery() async {
    _uploadStateService.startUpload();
    try {
      final result = await openGallery(
        onProgress: (current, total) {
          _uploadStateService.updateProgress(current, total);
        },
      );

      _uploadStateService.finishUpload();

      final uploadResult = UploadResult.fromMap(result);
      if (uploadResult.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${uploadResult.successCount}/${uploadResult.totalFiles} 이미지 업로드 완료'),
          ),
        );
      }
    } catch (e) {
      _uploadStateService.finishUpload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('업로드 중 오류 발생: $e'),
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
      body: Stack(
        children: [
          ListView.builder(
            itemCount: _photoSections.length,
            itemBuilder: (context, index) {
              final date = _photoSections.keys.elementAt(index);
              final imageCount = _photoSections.values.elementAt(index);
              return _DateSection(
                date: date,
                imageCount: imageCount,
                selectedPhotos: _photoSelectionService.selectedPhotos,
                isMultiSelectMode: _photoSelectionService.isMultiSelectMode,
                onPhotoTap: _photoSelectionService.onPhotoTap,
                onPhotoLongPress: _photoSelectionService.onPhotoLongPress,
              );
            },
          ),
          // Upload progress indicator on the left side
          if (_uploadStateService.isUploading)
            Positioned(
              left: 16,
              bottom: 16,
              child: _UploadProgressIndicator(
                current: _uploadStateService.uploadCurrent,
                total: _uploadStateService.uploadTotal,
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: _photoSelectionService.isMultiSelectMode
      ? null
      : ExpandableFab(
        openButtonBuilder: RotateFloatingActionButtonBuilder(
          child: const Icon(Icons.add),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        closeButtonBuilder: DefaultFloatingActionButtonBuilder(
          child: const Icon(Icons.close),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        type: ExpandableFabType.up,
        distance: 70,
        children: [
          FloatingActionButton.small(
            heroTag: 'file',
            onPressed: _handlePickFile,
            tooltip: '파일 선택',
            child: const Icon(Icons.insert_drive_file),
          ),
          FloatingActionButton.small(
            heroTag: 'folder',
            onPressed: _handlePickFolder,
            tooltip: '폴더 선택',
            child: const Icon(Icons.folder_open),
          ),
          FloatingActionButton.small(
            heroTag: 'gallery',
            onPressed: _handleOpenGallery,
            tooltip: '갤러리 열기',
            child: const Icon(Icons.photo_library),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    if (_photoSelectionService.isMultiSelectMode) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _photoSelectionService.toggleMultiSelectMode,
        ),
        title: Text('${_photoSelectionService.selectedCount}개 선택'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share action for selected photos
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              // TODO: Implement delete action for selected photos
            },
          ),
        ],
      );
    }

    return AppBar(
      title: const Text('AI Gallery'),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'select') {
              _photoSelectionService.toggleMultiSelectMode();
            }
            // TODO: Handle other options like sort
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'sort',
              child: Text('정렬'),
            ),
            const PopupMenuItem<String>(
              value: 'select',
              child: Text('선택'),
            ),
          ],
        ),
      ],
    );
  }
}

class _DateSection extends StatelessWidget {
  final String date;
  final int imageCount;
  final Set<String> selectedPhotos;
  final bool isMultiSelectMode;
  final Function(String) onPhotoTap;
  final Function(String) onPhotoLongPress;

  const _DateSection({
    required this.date,
    required this.imageCount,
    required this.selectedPhotos,
    required this.isMultiSelectMode,
    required this.onPhotoTap,
    required this.onPhotoLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            date,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2.0,
            mainAxisSpacing: 2.0,
          ),
          itemCount: imageCount,
          itemBuilder: (context, index) {
            final photoId = '$date-$index'; // Unique ID for each photo
            final isSelected = selectedPhotos.contains(photoId);
            return _PhotoItem(
              photoId: photoId,
              isSelected: isSelected,
              isMultiSelectMode: isMultiSelectMode,
              onTap: () => onPhotoTap(photoId),
              onLongPress: () => onPhotoLongPress(photoId),
            );
          },
        ),
      ],
    );
  }
}

class _PhotoItem extends StatelessWidget {
  final String photoId;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PhotoItem({
    required this.photoId,
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
          Container(
            color: Colors.grey[300],
            // Placeholder for the image
          ),
          if (isMultiSelectMode)
            Positioned(
              top: 4,
              right: 4,
              child: Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? Theme.of(context).primaryColor : Colors.white70,
              ),
            ),
          if (isSelected)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
            ),
        ],
      ),
    );
  }
}

class _UploadProgressIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _UploadProgressIndicator({
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : 0.0;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular progress indicator
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
          // Text showing progress
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$current',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '/ $total',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
