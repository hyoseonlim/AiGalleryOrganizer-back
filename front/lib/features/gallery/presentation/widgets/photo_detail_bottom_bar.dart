import 'package:flutter/material.dart';
import '../../domain/photo_detail_state_service.dart';

class PhotoDetailBottomBar extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onDownload;
  final VoidCallback onShowMetadata;
  final PhotoDetailStateService stateService;

  const PhotoDetailBottomBar({
    super.key,
    required this.onDelete,
    required this.onShare,
    required this.onDownload,
    required this.onShowMetadata,
    required this.stateService,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ActionButton(
              icon: Icons.info_outline,
              label: '정보',
              onPressed: onShowMetadata,
            ),
            _ActionButton(
              icon: Icons.share,
              label: '공유',
              onPressed: onShare,
            ),
            _ActionButton(
              icon: Icons.download,
              label: '다운로드',
              onPressed: onDownload,
            ),
            _ActionButton(
              icon: Icons.delete_outline,
              label: '삭제',
              onPressed: onDelete,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: buttonColor, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: buttonColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}