import 'package:flutter/material.dart';
import '../../domain/photo_detail_state_service.dart';

class PhotoDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final PhotoDetailStateService stateService;

  const PhotoDetailAppBar({
    super.key,
    required this.onBack,
    required this.stateService,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: onBack,
      ),
      title: ListenableBuilder(
        listenable: stateService,
        builder: (context, child) {
          final current = stateService.currentIndex + 1;
          final total = stateService.totalPhotos;
          return Text(
            '$current / $total',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          );
        },
      ),
      centerTitle: true,
      actions: [
        ListenableBuilder(
          listenable: stateService,
          builder: (context, child) {
            final photo = stateService.currentPhoto;
            if (photo?.fileName != null) {
              return IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('사진 정보'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (photo!.fileName != null)
                            Text('파일명: ${photo.fileName}'),
                          if (photo.fileSize != null)
                            Text('크기: ${_formatFileSize(photo.fileSize!)}'),
                          if (photo.createdAt != null)
                            Text('생성일: ${_formatDate(photo.createdAt!)}'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('닫기'),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}