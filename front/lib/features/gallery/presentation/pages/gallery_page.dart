import 'package:flutter/material.dart';
import 'package:front/features/gallery/domain/upload_service.dart';
import 'package:front/features/gallery/domain/upload_state_service.dart';
import 'package:front/features/gallery/domain/photo_selection_service.dart';
import 'package:front/features/gallery/domain/gallery_service.dart';
import 'package:front/features/gallery/domain/trash_service.dart';
import 'package:front/features/gallery/data/models/photo_models.dart';
import 'package:front/features/gallery/data/repositories/local_photo_repository.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'dart:io';
import 'dart:developer' as developer;
import 'photo_detail_page.dart';
import 'swipe_clean_page.dart';
import '../widgets/upload_progress_widget.dart';
import '../widgets/duplicate_detection_dialog.dart';

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

  /// Load photos from backend with local thumbnail cache
  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 백엔드에서 이미지 목록 불러오기 + 로컬 캐시 활용
      final photosByDate = await loadGalleryPhotos(
        onProgress: (current, total) {
          // 로딩 진행 상황 표시 (선택적)
          developer.log('이미지 로드 진행: $current/$total', name: 'GalleryPage');
        },
      );

      // 전체 사진 리스트 생성 (날짜별로 정렬)
      final allPhotos = <Photo>[];
      final sortedDates = photosByDate.keys.toList()..sort((a, b) => b.compareTo(a)); // 최신 날짜 우선
      for (final date in sortedDates) {
        allPhotos.addAll(photosByDate[date]!);
      }

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
          builder: (context) =>
              PhotoDetailPage(photos: _allPhotos, initialIndex: photoIndex),
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

  /// Handle delete action for selected photos
  Future<void> _handleDeleteSelectedPhotos() async {
    if (!_photoSelectionService.hasSelection) {
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사진 삭제'),
        content: Text('선택한 ${_photoSelectionService.selectedCount}개의 사진을 삭제하시겠습니까?'),
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
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    // Convert photo IDs to integers
    final selectedPhotoIds = _photoSelectionService.selectedPhotos.toList();
    final imageIds = <int>[];

    for (final photoId in selectedPhotoIds) {
      try {
        imageIds.add(int.parse(photoId));
      } catch (e) {
        // Skip invalid IDs
        developer.log('잘못된 사진 ID: $photoId', name: 'GalleryPage');
      }
    }

    if (imageIds.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('삭제할 수 있는 유효한 사진이 없습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${imageIds.length}개의 사진을 삭제하는 중...'),
            duration: const Duration(seconds: 30),
          ),
        );
      }

      // Delete photos using trash service
      final result = await softDeleteMultipleImages(
        imageIds,
        onProgress: (current, total) {
          developer.log('삭제 진행: $current/$total', name: 'GalleryPage');
        },
      );

      // Clear selection and exit multi-select mode
      _photoSelectionService.disableMultiSelectMode();

      // Hide loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      // Reload photos to reflect changes
      await _loadPhotos();

      // Show result
      if (mounted) {
        final successCount = result['successCount'] ?? 0;
        final failedCount = result['failedCount'] ?? 0;

        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                failedCount > 0
                    ? '$successCount개 삭제 완료, $failedCount개 실패'
                    : '$successCount개의 사진이 삭제되었습니다',
              ),
              backgroundColor: failedCount > 0 ? Colors.orange : Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('사진 삭제에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Clear selection
      _photoSelectionService.disableMultiSelectMode();

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

  Future<void> _handlePickFile() async {
    _uploadStateService.startUpload();
    try {
      final result = await pickFile(
        onProgress: (current, total) {
          _uploadStateService.updateProgress(current, total);
        },
        onPhotoSaved: (photo) {
          // 새 이미지 업로드 추적 시작
          _uploadStateService.addImageUpload(
            photo.id,
            photo.fileName ?? 'Unknown',
          );
          _onPhotoSaved(photo);
        },
        onStepCompleted: (photoId, step) {
          _uploadStateService.completeImageStep(photoId, step);
        },
        onStepFailed: (photoId, step, error) {
          _uploadStateService.failImageStep(photoId, step, error);
        },
      );

      _uploadStateService.finishUpload();

      final uploadResult = UploadResult.fromMap(result);

      // Show duplicate detection dialog if duplicates found
      final duplicates = result['duplicates'] as List<dynamic>? ?? [];
      final tempIdToFileNameMap =
          result['tempIdToFileNameMap'] as Map<int, String>? ?? {};
      if (duplicates.isNotEmpty && mounted) {
        await DuplicateDetectionDialog.show(
          context,
          duplicates: duplicates
              .map((d) => DuplicateImageInfo.fromMap(d as Map<String, dynamic>))
              .toList(),
          tempIdToFileNameMap: tempIdToFileNameMap,
        );
      }

      if (uploadResult.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${uploadResult.successCount}/${uploadResult.totalFiles} 파일 로컬 저장 완료',
            ),
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
        onPhotoSaved: (photo) {
          // 새 이미지 업로드 추적 시작
          _uploadStateService.addImageUpload(
            photo.id,
            photo.fileName ?? 'Unknown',
          );
          _onPhotoSaved(photo);
        },
        onStepCompleted: (photoId, step) {
          _uploadStateService.completeImageStep(photoId, step);
        },
        onStepFailed: (photoId, step, error) {
          _uploadStateService.failImageStep(photoId, step, error);
        },
      );

      _uploadStateService.finishUpload();

      final uploadResult = UploadResult.fromMap(result);

      // Show duplicate detection dialog if duplicates found
      final duplicates = result['duplicates'] as List<dynamic>? ?? [];
      final tempIdToFileNameMap =
          result['tempIdToFileNameMap'] as Map<int, String>? ?? {};
      if (duplicates.isNotEmpty && mounted) {
        await DuplicateDetectionDialog.show(
          context,
          duplicates: duplicates
              .map((d) => DuplicateImageInfo.fromMap(d as Map<String, dynamic>))
              .toList(),
          tempIdToFileNameMap: tempIdToFileNameMap,
        );
      }

      if (uploadResult.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${uploadResult.successCount}/${uploadResult.totalFiles} 파일 로컬 저장 완료',
            ),
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
        onPhotoSaved: (photo) {
          // 새 이미지 업로드 추적 시작
          _uploadStateService.addImageUpload(
            photo.id,
            photo.fileName ?? 'Unknown',
          );
          _onPhotoSaved(photo);
        },
        onStepCompleted: (photoId, step) {
          _uploadStateService.completeImageStep(photoId, step);
        },
        onStepFailed: (photoId, step, error) {
          _uploadStateService.failImageStep(photoId, step, error);
        },
      );

      _uploadStateService.finishUpload();

      final uploadResult = UploadResult.fromMap(result);

      // Show duplicate detection dialog if duplicates found
      final duplicates = result['duplicates'] as List<dynamic>? ?? [];
      final tempIdToFileNameMap =
          result['tempIdToFileNameMap'] as Map<int, String>? ?? {};
      if (duplicates.isNotEmpty && mounted) {
        await DuplicateDetectionDialog.show(
          context,
          duplicates: duplicates
              .map((d) => DuplicateImageInfo.fromMap(d as Map<String, dynamic>))
              .toList(),
          tempIdToFileNameMap: tempIdToFileNameMap,
        );
      }

      if (uploadResult.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${uploadResult.successCount}/${uploadResult.totalFiles} 이미지 로컬 저장 완료',
            ),
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
    final filteredPhotosByDate =
        _isSearchBarVisible && _searchController.text.isNotEmpty
        ? _filterPhotosByQuery(_searchController.text)
        : _photosByDate;

    return Scaffold(
      appBar: _buildAppBar(),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Show search bar when pulling down at the top
          if (notification is ScrollUpdateNotification) {
            if (_scrollController.hasClients &&
                _scrollController.offset <= -100 &&
                !_isSearchBarVisible) {
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
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
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      size: 20,
                                    ),
                                    suffixIcon:
                                        _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.clear,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _searchController.clear();
                                              });
                                            },
                                          )
                                        : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).primaryColor,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
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
                                  _isSearchBarVisible &&
                                          _searchController.text.isNotEmpty
                                      ? Icons.search_off
                                      : Icons.photo_library_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _isSearchBarVisible &&
                                          _searchController.text.isNotEmpty
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
                                  _isSearchBarVisible &&
                                          _searchController.text.isNotEmpty
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
                            final date = filteredPhotosByDate.keys.elementAt(
                              index,
                            );
                            final photos = filteredPhotosByDate[date]!;
                            return _DateSection(
                              date: date,
                              photos: photos,
                              localRepo: _localRepo,
                              selectedPhotos:
                                  _photoSelectionService.selectedPhotos,
                              isMultiSelectMode:
                                  _photoSelectionService.isMultiSelectMode,
                              onPhotoTap: (photoId) {
                                if (_photoSelectionService.isMultiSelectMode) {
                                  _photoSelectionService.onPhotoTap(photoId);
                                } else {
                                  _navigateToPhotoDetail(photoId);
                                }
                              },
                              onPhotoLongPress:
                                  _photoSelectionService.onPhotoLongPress,
                            );
                          },
                        ),
                ),
              ],
            ),
            // Upload progress indicator on the left side
            if (_uploadStateService.isUploading ||
                _uploadStateService.allUploads.isNotEmpty)
              Positioned(
                left: 16,
                bottom: 16,
                child: ExpandableUploadProgress(
                  overallProgress: _uploadStateService.overallProgress,
                  activeUploads: _uploadStateService.activeUploads,
                  completedUploads: _uploadStateService.completedUploads,
                  onRetry: (photoId) async {
                    // 재시도 처리: 로컬에서 원본 파일을 가져와 재업로드
                    try {
                      final photo = _allPhotos.firstWhere(
                        (p) => p.id == photoId,
                      );
                      final originalFile = await _localRepo.getOriginalPhoto(
                        photoId,
                      );

                      if (originalFile != null) {
                        // 실패 상태 초기화
                        _uploadStateService.retryImage(photoId);

                        // 재업로드 시작
                        await retryUpload(
                          photo,
                          originalFile,
                          onStepCompleted: (retryPhotoId, step) {
                            _uploadStateService.completeImageStep(
                              retryPhotoId,
                              step,
                            );
                          },
                          onStepFailed: (retryPhotoId, step, error) {
                            _uploadStateService.failImageStep(
                              retryPhotoId,
                              step,
                              error,
                            );
                          },
                        );
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('원본 파일을 찾을 수 없습니다'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('재시도 중 오류: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
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
                FloatingActionButton.small(
                  heroTag: 'swipe-clean',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SwipeCleanPage()),
                    );
                  },
                  tooltip: '스와이프 정리',
                  child: const Icon(Icons.swipe),
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
            onPressed: _handleDeleteSelectedPhotos,
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
            const PopupMenuItem<String>(value: 'sort', child: Text('정렬')),
            const PopupMenuItem<String>(value: 'select', child: Text('선택')),
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
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
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.white70,
              ),
            ),
          // Selection overlay
          if (isSelected) Container(color: Colors.black.withValues(alpha: 0.3)),
        ],
      ),
    );
  }
}
