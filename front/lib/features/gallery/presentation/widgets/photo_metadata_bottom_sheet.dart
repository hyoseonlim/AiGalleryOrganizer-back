import 'package:flutter/material.dart';
import '../../data/models/photo_models.dart';
import '../../domain/tag_service.dart';
import '../../domain/photo_detail_state_service.dart';

class PhotoMetadataBottomSheet extends StatefulWidget {
  final Photo photo;
  final PhotoDetailStateService stateService;

  const PhotoMetadataBottomSheet({
    super.key,
    required this.photo,
    required this.stateService,
  });

  @override
  State<PhotoMetadataBottomSheet> createState() =>
      _PhotoMetadataBottomSheetState();
}

class _PhotoMetadataBottomSheetState extends State<PhotoMetadataBottomSheet> {
  final TextEditingController _tagController = TextEditingController();
  bool _isAddingTag = false;

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _addTag() async {
    final tagName = _tagController.text.trim();
    if (tagName.isEmpty) return;

    setState(() => _isAddingTag = true);

    try {
      final newTag = await addUserTag(widget.photo.id, tagName);

      if (newTag != null && mounted) {
        // Update photo metadata in state and refresh UI
        setState(() {
          final updatedMetadata = widget.photo.metadata.copyWith(
            userTags: [...widget.photo.metadata.userTags, newTag],
          );
          final updatedPhoto = widget.photo.copyWith(metadata: updatedMetadata);
          widget.stateService.updatePhoto(updatedPhoto);
          _isAddingTag = false;
        });

        _tagController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('태그 "$tagName"이(가) 추가되었습니다')),
        );
      } else if (mounted) {
        setState(() => _isAddingTag = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('태그 추가에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAddingTag = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteTag(PhotoTag tag) async {
    // Confirm deletion
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('태그 삭제'),
        content: Text('"${tag.name}" 태그를 삭제하시겠습니까?'),
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

    if (confirmed != true) return;

    try {
      final success = await deleteTag(widget.photo.id, tag.id);

      if (success && mounted) {
        // Update photo metadata in state and refresh UI
        setState(() {
          final updatedUserTags = widget.photo.metadata.userTags
              .where((t) => t.id != tag.id)
              .toList();
          final updatedMetadata = widget.photo.metadata.copyWith(
            userTags: updatedUserTags,
          );
          final updatedPhoto = widget.photo.copyWith(metadata: updatedMetadata);
          widget.stateService.updatePhoto(updatedPhoto);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('태그 "${tag.name}"이(가) 삭제되었습니다')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('태그 삭제에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final metadata = widget.photo.metadata;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
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

              // Title
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      '사진 정보',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Basic metadata
                    if (widget.photo.fileName != null)
                      _MetadataItem(
                        icon: Icons.image,
                        label: '파일명',
                        value: widget.photo.fileName!,
                      ),
                    if (widget.photo.fileSize != null)
                      _MetadataItem(
                        icon: Icons.storage,
                        label: '파일 크기',
                        value: _formatFileSize(widget.photo.fileSize!),
                      ),
                    if (widget.photo.createdAt != null)
                      _MetadataItem(
                        icon: Icons.calendar_today,
                        label: '업로드 날짜',
                        value: _formatDate(widget.photo.createdAt!),
                      ),
                    if (metadata.dateTaken != null)
                      _MetadataItem(
                        icon: Icons.photo_camera,
                        label: '촬영 날짜',
                        value: _formatDate(metadata.dateTaken!),
                      ),
                    if (metadata.camera != null)
                      _MetadataItem(
                        icon: Icons.camera_alt,
                        label: '카메라',
                        value: metadata.camera!,
                      ),
                    if (metadata.resolution != null)
                      _MetadataItem(
                        icon: Icons.aspect_ratio,
                        label: '해상도',
                        value: metadata.resolution!,
                      ),
                    if (metadata.width != null && metadata.height != null)
                      _MetadataItem(
                        icon: Icons.photo_size_select_large,
                        label: '크기 (픽셀)',
                        value: '${metadata.width} × ${metadata.height}',
                      ),
                    if (metadata.mimeType != null)
                      _MetadataItem(
                        icon: Icons.insert_drive_file,
                        label: '파일 형식',
                        value: metadata.mimeType!,
                      ),
                    if (metadata.location != null)
                      _MetadataItem(
                        icon: Icons.location_on,
                        label: '위치',
                        value: metadata.location!,
                      ),
                    if (metadata.latitude != null && metadata.longitude != null)
                      _MetadataItem(
                        icon: Icons.gps_fixed,
                        label: 'GPS 좌표',
                        value: '${metadata.latitude!.toStringAsFixed(6)}, ${metadata.longitude!.toStringAsFixed(6)}',
                      ),

                    const SizedBox(height: 24),

                    // Categories (카테고리 - category가 null인 태그들)
                    if (metadata.systemTags.where((tag) => tag.category == null).isNotEmpty) ...[
                      const Text(
                        '카테고리',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: metadata.systemTags
                            .where((tag) => tag.category == null)
                            .map((tag) => _TagChip(
                                  tag: tag,
                                  onDelete: null, // Categories cannot be deleted
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // AI tags (하위 태그 - category가 있는 태그들)
                    if (metadata.systemTags.where((tag) => tag.category != null).isNotEmpty) ...[
                      const Text(
                        'AI 태그',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: metadata.systemTags
                            .where((tag) => tag.category != null)
                            .map((tag) => _TagChip(
                                  tag: tag,
                                  onDelete: null, // AI tags cannot be deleted
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // User tags
                    const Text(
                      '내 태그',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tag input field
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagController,
                            decoration: InputDecoration(
                              hintText: '태그 추가...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onSubmitted: (_) => _addTag(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isAddingTag ? null : _addTag,
                          child: _isAddingTag
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('추가'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // User tags display
                    if (metadata.userTags.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          '태그가 없습니다. 태그를 추가해보세요!',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: metadata.userTags
                            .map((tag) => _TagChip(
                                  tag: tag,
                                  onDelete: () => _deleteTag(tag),
                                ))
                            .toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _MetadataItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetadataItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final PhotoTag tag;
  final VoidCallback? onDelete;

  const _TagChip({
    required this.tag,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isSystemTag = tag.type == TagType.system;

    return Chip(
      label: Text(tag.displayName), // category:tag_name 형식으로 표시
      backgroundColor: isSystemTag
          ? Colors.blue.withValues(alpha: 0.1)
          : Colors.green.withValues(alpha: 0.1),
      side: BorderSide(
        color: isSystemTag ? Colors.blue : Colors.green,
        width: 1,
      ),
      deleteIcon: onDelete != null
          ? const Icon(Icons.close, size: 18)
          : null,
      onDeleted: onDelete,
      labelStyle: TextStyle(
        color: isSystemTag ? Colors.blue[700] : Colors.green[700],
        fontSize: 13,
      ),
    );
  }
}