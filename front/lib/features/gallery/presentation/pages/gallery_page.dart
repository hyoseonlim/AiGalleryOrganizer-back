import 'package:flutter/material.dart';
import 'package:front/features/gallery/domain/upload_service.dart';
import 'package:front/features/gallery/domain/upload_state_service.dart';
import 'package:front/features/gallery/domain/photo_selection_service.dart';
import 'package:front/features/gallery/data/models/photo_models.dart';
import 'package:front/features/gallery/data/repositories/local_photo_repository.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'dart:io';
import 'photo_detail_page.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  // Photo data grouped by date
  Map<String, List<Photo>> _photosByDate = {};

  // All photos
  List<Photo> _allPhotos = [];

  // Domain services
  late final UploadStateService _uploadStateService;
  late final PhotoSelectionService _photoSelectionService;
  final _localRepo = LocalPhotoRepository();

  // Loading state
  bool _isLoading = true;

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  // Search bar visibility
  bool _isSearchBarVisible = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _uploadStateService = UploadStateService();
    _photoSelectionService = PhotoSelectionService();

    // Listen to service changes and rebuild UI
    _uploadStateService.addListener(_onUploadStateChanged);
    _photoSelectionService.addListener(_onSelectionStateChanged);

    // Load photos from local repository
    _loadPhotos();
  }

  /// Load photos from local repository
  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final photosByDate = await _localRepo.getPhotosByDate();
      final allPhotos = await _localRepo.getAllPhotos();

      setState(() {
        _photosByDate = photosByDate;
        _allPhotos = allPhotos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사진 로드 중 오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Add photo to UI immediately when saved
  void _onPhotoSaved(Photo photo) {
    setState(() {
      // Add to all photos list
      _allPhotos.insert(0, photo);

      // Add to date-grouped map
      final dateKey = _formatDate(photo.createdAt ?? DateTime.now());
      if (!_photosByDate.containsKey(dateKey)) {
        _photosByDate[dateKey] = [];
      }
      _photosByDate[dateKey]!.insert(0, photo);
    });
  }

  /// Format date for grouping
  String _formatDate(DateTime date) {
    final year = date.year;
    final month = date.month;
    final day = date.day;
    return '$year년 $month월 $day일';
  }

  void _navigateToPhotoDetail(String photoId) async {
    final photoIndex = _allPhotos.indexWhere((photo) => photo.id == photoId);
    if (photoIndex != -1) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PhotoDetailPage(
            photos: _allPhotos,
            initialIndex: photoIndex,
          ),
        ),
      );

      // Reload photos if any were deleted
      if (result == true && mounted) {
        await _loadPhotos();
      }
    }
  }

  @override
  void dispose() {
    _uploadStateService.removeListener(_onUploadStateChanged);
    _photoSelectionService.removeListener(_onSelectionStateChanged);
    _uploadStateService.dispose();
    _photoSelectionService.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onUploadStateChanged() {
    setState(() {});
  }

  void _onSelectionStateChanged() {
    setState(() {});
  }

  /// Toggle search bar visibility
  void _toggleSearchBar() {
    setState(() {
      _isSearchBarVisible = !_isSearchBarVisible;
      if (!_isSearchBarVisible) {
        _searchController.clear();
      }
    });
  }

  Future<void> _handlePickFile() async {
    _uploadStateService.startUpload();
    try {
      final result = await pickFile(
        onProgress: (current, total) {
          _uploadStateService.updateProgress(current, total);
        },
        onPhotoSaved: _onPhotoSaved,
      );

      _uploadStateService.finishUpload();

      final uploadResult = UploadResult.fromMap(result);
      if (uploadResult.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${uploadResult.successCount}/${uploadResult.totalFiles} 파일 로컬 저장 완료'),
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
        onPhotoSaved: _onPhotoSaved,
      );

      _uploadStateService.finishUpload();

      final uploadResult = UploadResult.fromMap(result);
      if (uploadResult.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${uploadResult.successCount}/${uploadResult.totalFiles} 파일 로컬 저장 완료'),
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
        onPhotoSaved: _onPhotoSaved,
      );

      _uploadStateService.finishUpload();

      final uploadResult = UploadResult.fromMap(result);
      if (uploadResult.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${uploadResult.successCount}/${uploadResult.totalFiles} 이미지 로컬 저장 완료'),
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
    // Filter photos based on search query
    final filteredPhotosByDate = _isSearchBarVisible && _searchController.text.isNotEmpty
        ? _filterPhotosByQuery(_searchController.text)
        : _photosByDate;

    return Scaffold(
      appBar: _buildAppBar(),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Show search bar when pulling down at the top
          if (notification is ScrollUpdateNotification) {
            if (_scrollController.hasClients && _scrollController.offset <= -100 && !_isSearchBarVisible) {
              _toggleSearchBar();
            }
          }
          return false;
        },
        child: Stack(
          children: [
            Column(
              children: [
                // Search bar that slides down from top
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: _isSearchBarVisible ? 70 : 0,
                  child: _isSearchBarVisible
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    hintText: '파일명, 태그로 검색',
                                    prefixIcon: const Icon(Icons.search, size: 20),
                                    suffixIcon: _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear, size: 20),
                                            onPressed: () {
                                              setState(() {
                                                _searchController.clear();
                                              });
                                            },
                                          )
                                        : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    isDense: true,
                                  ),
                                  onChanged: (value) {
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: _toggleSearchBar,
                                tooltip: '검색 닫기',
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                // Main content
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredPhotosByDate.isEmpty
                          ? Center(
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isSearchBarVisible && _searchController.text.isNotEmpty
                                          ? Icons.search_off
                                          : Icons.photo_library_outlined,
                                      size: 80,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _isSearchBarVisible && _searchController.text.isNotEmpty
                                          ? '검색 결과가 없습니다'
                                          : '사진이 없습니다',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _isSearchBarVisible && _searchController.text.isNotEmpty
                                          ? '다른 검색어를 입력해보세요'
                                          : '하단의 + 버튼을 눌러 사진을 추가하세요',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    if (!_isSearchBarVisible)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          '↓ 아래로 당겨서 검색',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: filteredPhotosByDate.length,
                              itemBuilder: (context, index) {
                                final date = filteredPhotosByDate.keys.elementAt(index);
                                final photos = filteredPhotosByDate[date]!;
                                return _DateSection(
                                  date: date,
                                  photos: photos,
                                  localRepo: _localRepo,
                                  selectedPhotos: _photoSelectionService.selectedPhotos,
                                  isMultiSelectMode: _photoSelectionService.isMultiSelectMode,
                                  onPhotoTap: (photoId) {
                                    if (_photoSelectionService.isMultiSelectMode) {
                                      _photoSelectionService.onPhotoTap(photoId);
                                    } else {
                                      _navigateToPhotoDetail(photoId);
                                    }
                                  },
                                  onPhotoLongPress: _photoSelectionService.onPhotoLongPress,
                                );
                              },
                            ),
                ),
              ],
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

  /// Filter photos by search query
  Map<String, List<Photo>> _filterPhotosByQuery(String query) {
    final lowerQuery = query.toLowerCase();
    final filtered = <String, List<Photo>>{};

    for (final entry in _photosByDate.entries) {
      final matchingPhotos = entry.value.where((photo) {
        final fileName = (photo.fileName ?? '').toLowerCase();
        final systemTags = photo.metadata.systemTags.join(' ').toLowerCase();
        final userTags = photo.metadata.userTags.join(' ').toLowerCase();

        return fileName.contains(lowerQuery) ||
               systemTags.contains(lowerQuery) ||
               userTags.contains(lowerQuery);
      }).toList();

      if (matchingPhotos.isNotEmpty) {
        filtered[entry.key] = matchingPhotos;
      }
    }

    return filtered;
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
  final List<Photo> photos;
  final LocalPhotoRepository localRepo;
  final Set<String> selectedPhotos;
  final bool isMultiSelectMode;
  final Function(String) onPhotoTap;
  final Function(String) onPhotoLongPress;

  const _DateSection({
    required this.date,
    required this.photos,
    required this.localRepo,
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
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            final isSelected = selectedPhotos.contains(photo.id);
            return _PhotoItem(
              photo: photo,
              localRepo: localRepo,
              isSelected: isSelected,
              isMultiSelectMode: isMultiSelectMode,
              onTap: () => onPhotoTap(photo.id),
              onLongPress: () => onPhotoLongPress(photo.id),
            );
          },
        ),
      ],
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
          // Display thumbnail from cache only
          FutureBuilder<File?>(
            future: localRepo.getThumbnail(photo.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Loading placeholder
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              } else if (snapshot.hasData && snapshot.data != null) {
                // Display thumbnail
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
                // No thumbnail available
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.image, color: Colors.grey),
                  ),
                );
              }
            },
          ),
          // Upload status indicator
          if (photo.uploadStatus == UploadStatus.pending ||
              photo.uploadStatus == UploadStatus.uploading)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: photo.uploadStatus == UploadStatus.uploading
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.cloud_upload_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
              ),
            ),
          // Failed upload indicator
          if (photo.uploadStatus == UploadStatus.failed)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          // Multi-select checkbox
          if (isMultiSelectMode)
            Positioned(
              top: 4,
              right: 4,
              child: Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? Theme.of(context).primaryColor : Colors.white70,
              ),
            ),
          // Selection overlay
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

/// Search bottom sheet widget
class _SearchBottomSheet extends StatefulWidget {
  final TextEditingController searchController;
  final List<Photo> allPhotos;
  final Function(String) onPhotoTap;

  const _SearchBottomSheet({
    required this.searchController,
    required this.allPhotos,
    required this.onPhotoTap,
  });

  @override
  State<_SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<_SearchBottomSheet> {
  List<Photo> _filteredPhotos = [];
  final _localRepo = LocalPhotoRepository();

  @override
  void initState() {
    super.initState();
    _filteredPhotos = widget.allPhotos;
    widget.searchController.addListener(_filterPhotos);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_filterPhotos);
    super.dispose();
  }

  void _filterPhotos() {
    final query = widget.searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredPhotos = widget.allPhotos;
      } else {
        _filteredPhotos = widget.allPhotos.where((photo) {
          // Search by filename
          final fileName = (photo.fileName ?? '').toLowerCase();
          // Search by tags
          final systemTags = photo.metadata.systemTags.join(' ').toLowerCase();
          final userTags = photo.metadata.userTags.join(' ').toLowerCase();

          return fileName.contains(query) ||
                 systemTags.contains(query) ||
                 userTags.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: widget.searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '파일명, 태그로 검색',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: widget.searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              widget.searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              // Search results count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_filteredPhotos.length}개의 사진',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              // Results grid
              Expanded(
                child: _filteredPhotos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '검색 결과가 없습니다',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _filteredPhotos.length,
                        itemBuilder: (context, index) {
                          final photo = _filteredPhotos[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              widget.onPhotoTap(photo.id);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: FutureBuilder<File?>(
                                future: _localRepo.getThumbnail(photo.id),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData && snapshot.data != null) {
                                    return Image.file(
                                      snapshot.data!,
                                      fit: BoxFit.cover,
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
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
