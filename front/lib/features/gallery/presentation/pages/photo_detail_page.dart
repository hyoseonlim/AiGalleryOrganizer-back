import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:front/core/network/network_policy_service.dart';
import '../../data/models/photo_models.dart';
import '../../data/repositories/local_photo_repository.dart';
import '../../di/gallery_service_locator.dart';
import '../../domain/photo_detail_state_service.dart';
import '../../domain/tag_service.dart' as tag_service;
import '../../domain/trash_service.dart';
import '../widgets/photo_detail_app_bar.dart';
import '../widgets/photo_viewer.dart';
import '../widgets/photo_detail_bottom_bar.dart';
import '../widgets/photo_metadata_bottom_sheet.dart';

class PhotoDetailPage extends StatefulWidget {
  final List<Photo> photos;
  final int initialIndex;

  const PhotoDetailPage({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<PhotoDetailPage> createState() => _PhotoDetailPageState();
}

class _PhotoDetailPageState extends State<PhotoDetailPage> {
  late final PhotoDetailStateService _stateService;
  late final PageController _pageController;
  final _localRepo = LocalPhotoRepository();

  @override
  void initState() {
    super.initState();
    // Get singleton service from DI container
    _stateService = GalleryServiceLocator().photoDetailStateService;
    _stateService.initialize(widget.photos, widget.initialIndex);

    // Initialize page controller with starting index
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    _stateService.jumpToIndex(index);
  }

  void _onPreviousPhoto() {
    if (_stateService.hasPrevious) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onNextPhoto() {
    if (_stateService.hasNext) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onBack() {
    Navigator.of(context).pop();
  }

  void _onDelete() async {
    final photo = _stateService.currentPhoto;
    if (photo == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사진 삭제'),
        content: const Text('이 사진을 휴지통으로 이동하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Text('삭제 중...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      try {
        // Soft delete from backend (move to trash)
        final imageId = int.parse(photo.id);
        final result = await softDeleteImage(imageId);

        // Clear snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
        }

        if (result['success'] == true) {
          // Delete from local repository
          await _localRepo.deletePhoto(photo.id);

          // Remove from state
          _stateService.removeCurrentPhoto();

          // If no more photos, go back
          if (_stateService.totalPhotos == 0) {
            if (mounted) {
              Navigator.of(context).pop(true); // Return true to indicate deletion
            }
          } else {
            // Update page controller to current index
            _pageController.jumpToPage(_stateService.currentIndex);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('사진이 휴지통으로 이동되었습니다'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('삭제 실패: ${result['error'] ?? '알 수 없는 오류'}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
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
  }

  void _onShare() async {
    final photo = _stateService.currentPhoto;
    if (photo == null) return;

    // TODO: Implement share functionality using share_plus package
    // await sharePhoto(photo.id, photo.url);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('공유 기능은 준비중입니다')));
    }
  }

  void _onDownload() async {
    final photo = _stateService.currentPhoto;
    if (photo == null) return;

    // 이미 로컬에 있는지 확인
    final localFile = await _localRepo.getOriginalPhoto(photo.id);
    if (localFile != null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('이미 다운로드된 사진입니다')));
      }
      return;
    }

    // remoteUrl이 없으면 다운로드 불가
    if (photo.remoteUrl == null || photo.remoteUrl!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('백엔드 업로드가 완료되지 않았습니다'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Show downloading snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Text('원본 이미지 다운로드 중...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    try {
      // 원격에서 다운로드
      await NetworkPolicyService.instance.ensureAllowedConnectivity();
      final response = await http.get(Uri.parse(photo.remoteUrl!));

      if (response.statusCode == 200) {
        // 로컬에 저장
        await _localRepo.saveOriginalPhoto(photo.id, response.bodyBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('원본 이미지 다운로드 완료'),
              backgroundColor: Colors.green,
            ),
          );
          // 화면 새로고침을 위해 setState 호출
          setState(() {});
        }
      } else {
        throw Exception('다운로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('다운로드 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showMetadata() async {
    final photo = _stateService.currentPhoto;
    if (photo == null) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Fetch updated image details with tags from backend
      final updatedPhoto = await tag_service.fetchImageDetails(photo.id);

      // Close loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Merge updated AI tags with existing user tags
      Photo photoToShow;
      if (updatedPhoto != null) {
        // Preserve existing user tags and update with new AI tags
        photoToShow = updatedPhoto.copyWith(
          metadata: updatedPhoto.metadata.copyWith(
            userTags: photo.metadata.userTags, // Keep existing user tags
          ),
        );
      } else {
        photoToShow = photo;
      }

      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => PhotoMetadataBottomSheet(
            photo: photoToShow,
            stateService: _stateService,
          ),
        );
      }
    } catch (e) {
      // Close loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('태그 정보를 불러오는데 실패했습니다: $e'),
            backgroundColor: Colors.orange,
          ),
        );

        // Show metadata anyway with current photo
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => PhotoMetadataBottomSheet(
            photo: photo,
            stateService: _stateService,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: PhotoDetailAppBar(onBack: _onBack, stateService: _stateService),
      body: ListenableBuilder(
        listenable: _stateService,
        builder: (context, child) {
          if (_stateService.photos.isEmpty) {
            return const Center(
              child: Text('사진이 없습니다', style: TextStyle(color: Colors.white)),
            );
          }

          return Stack(
            children: [
              // Photo viewer with page view
              PhotoViewer(
                photos: _stateService.photos,
                pageController: _pageController,
                onPageChanged: _onPageChanged,
              ),
              // Navigation arrows for horizontal swipe hint
              if (_stateService.hasPrevious)
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Colors.white70,
                        size: 48,
                      ),
                      onPressed: _onPreviousPhoto,
                    ),
                  ),
                ),
              if (_stateService.hasNext)
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white70,
                        size: 48,
                      ),
                      onPressed: _onNextPhoto,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: PhotoDetailBottomBar(
        onDelete: _onDelete,
        onShare: _onShare,
        onDownload: _onDownload,
        onShowMetadata: _showMetadata,
        stateService: _stateService,
      ),
    );
  }
}
