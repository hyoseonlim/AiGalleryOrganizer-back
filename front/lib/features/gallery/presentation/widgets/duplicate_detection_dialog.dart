import 'package:flutter/material.dart';
import '../../data/models/photo_models.dart';

/// 중복 이미지 검출 다이얼로그
/// 업로드하려는 이미지 중 중복된 이미지를 표시하고 사용자에게 알림
class DuplicateDetectionDialog extends StatelessWidget {
  final List<DuplicateImageInfo> duplicates;
  final Map<int, String> tempIdToFileNameMap;  // 임시 ID -> 파일명 매핑
  final VoidCallback? onConfirm;

  const DuplicateDetectionDialog({
    super.key,
    required this.duplicates,
    required this.tempIdToFileNameMap,
    this.onConfirm,
  });

  /// 다이얼로그 표시
  static Future<void> show(
    BuildContext context, {
    required List<DuplicateImageInfo> duplicates,
    required Map<int, String> tempIdToFileNameMap,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DuplicateDetectionDialog(
        duplicates: duplicates,
        tempIdToFileNameMap: tempIdToFileNameMap,
        onConfirm: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange[700],
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            '중복 이미지 검출',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '선택하신 이미지 중 ${duplicates.length}개의 이미지가 이미 갤러리에 존재합니다.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '중복된 이미지는 업로드되지 않습니다.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
            // 중복 이미지 리스트
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: duplicates.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey[200],
                  ),
                  itemBuilder: (context, index) {
                    final duplicate = duplicates[index];
                    final fileName = tempIdToFileNameMap[duplicate.tempId] ??
                        '알 수 없는 파일';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange[100],
                        child: Icon(
                          Icons.image,
                          color: Colors.orange[700],
                          size: 20,
                        ),
                      ),
                      title: Text(
                        fileName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '기존 이미지 ID: ${duplicate.existingImageId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: Icon(
                        Icons.check_circle_outline,
                        color: Colors.orange[700],
                        size: 20,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onConfirm ?? () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text(
            '확인',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}