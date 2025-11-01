import 'package:flutter/material.dart';
import 'dart:io';
import '../../data/models/photo_models.dart';
import '../../data/repositories/local_photo_repository.dart';
import '../../domain/download_service.dart';

class PhotoViewer extends StatelessWidget {
  final List<Photo> photos;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;

  const PhotoViewer({
    super.key,
    required this.photos,
    required this.pageController,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: pageController,
      onPageChanged: onPageChanged,
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return PhotoImageWidget(photo: photo);
      },
    );
  }
}

class PhotoImageWidget extends StatefulWidget {
  final Photo photo;

  const PhotoImageWidget({
    super.key,
    required this.photo,
  });

  @override
  State<PhotoImageWidget> createState() => _PhotoImageWidgetState();
}

class _PhotoImageWidgetState extends State<PhotoImageWidget> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        if (_transformationController.value.getMaxScaleOnAxis() > 1.0) {
          _resetZoom();
        } else {
          _transformationController.value = Matrix4.diagonal3Values(2.0, 2.0, 1.0);
        }
      },
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1.0,
        maxScale: 4.0,
        child: Center(
          child: _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final localRepo = LocalPhotoRepository();

    return FutureBuilder<File?>(
      future: localRepo.getOriginalPhoto(widget.photo.id),
      builder: (context, localSnapshot) {
        // 1. 로컬에 원본이 있으면 로컬에서 로드
        if (localSnapshot.hasData && localSnapshot.data != null) {
          return Image.file(
            localSnapshot.data!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // 로컬 파일 로드 실패 시 원격에서 시도
              return _buildNetworkImage();
            },
          );
        }

        // 2. 로컬에 없으면 원격에서 로드
        if (localSnapshot.connectionState == ConnectionState.done) {
          return _buildNetworkImage();
        }

        // 3. 로컬 확인 중
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      },
    );
  }

  Widget _buildNetworkImage() {
    // API에서 view URL 받아오기
    return FutureBuilder<ImageViewableResponse?>(
      future: getImageViewUrl(int.parse(widget.photo.id)),
      builder: (context, urlSnapshot) {
        // URL 받아오는 중
        if (urlSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  '이미지 URL 조회 중...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          );
        }

        // URL 받아오기 실패
        if (urlSnapshot.hasError || !urlSnapshot.hasData || urlSnapshot.data == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white70, size: 64),
                const SizedBox(height: 16),
                const Text(
                  '이미지 URL을 가져올 수 없습니다',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                if (urlSnapshot.hasError)
                  Text(
                    '오류: ${urlSnapshot.error}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          );
        }

        // URL 받아오기 성공 - 이미지 로드
        final viewUrl = urlSnapshot.data!.url;
        return Image.network(
          viewUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '이미지 다운로드 중...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white70, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    '이미지를 불러올 수 없습니다',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'URL: $viewUrl',
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}