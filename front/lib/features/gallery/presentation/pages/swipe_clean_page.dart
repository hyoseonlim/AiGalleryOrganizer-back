import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/swipe_clean_controller.dart';
import '../../data/models/photo_models.dart';

class SwipeCleanPage extends StatefulWidget {
  const SwipeCleanPage({super.key});

  @override
  State<SwipeCleanPage> createState() => _SwipeCleanPageState();
}

class _SwipeCleanPageState extends State<SwipeCleanPage> {
  late final SwipeCleanController _controller;
  Color? _overlayColor;
  Timer? _overlayTimer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = SwipeCleanController()
      ..addListener(_onControllerChanged)
      ..loadImages();
  }

  @override
  void dispose() {
    _overlayTimer?.cancel();
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _showOverlay(Color color) {
    _overlayTimer?.cancel();
    setState(() {
      _overlayColor = color.withOpacity(0.35);
    });
    _overlayTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        _overlayColor = null;
      });
    });
  }

  Future<void> _handleSwipe(bool keep) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });
    _showOverlay(keep ? Colors.green : Colors.red);
    if (keep) {
      await _controller.keepCurrent();
    } else {
      await _controller.discardCurrent();
    }
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
    });
  }

  PopupMenuButton<SwipeOrder> _buildOrderMenu() {
    return PopupMenuButton<SwipeOrder>(
      initialValue: _controller.order,
      onSelected: (value) => _controller.changeOrder(value),
      itemBuilder: (context) => const [
        PopupMenuItem(value: SwipeOrder.oldest, child: Text('오래된 순')),
        PopupMenuItem(value: SwipeOrder.random, child: Text('무작위 순')),
      ],
      icon: const Icon(Icons.more_vert),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('스와이프 정리 모드'),
        actions: [_buildOrderMenu()],
      ),
      body: Stack(
        children: [
          _buildBody(theme),
          if (_overlayColor != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              color: _overlayColor,
            ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.errorMessage != null && !_controller.hasImages) {
      return _buildMessageCard(_controller.errorMessage!);
    }
    if (!_controller.hasImages) {
      return _buildMessageCard('지금은 분석 결과가 없습니다.');
    }

    final image = _controller.currentImage;

    return FutureBuilder(
      future: _controller.currentImageView,
      builder: (context, snapshot) {
        Widget child;
        if (snapshot.connectionState == ConnectionState.waiting) {
          child = const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          child = _buildMessageCard('이미지를 불러오지 못했습니다.');
        } else if (!snapshot.hasData || snapshot.data == null) {
          child = _buildMessageCard('이미지를 불러오지 못했습니다.');
        } else {
          final view = snapshot.data!;
          child = _buildImageContent(theme, image!, view.url);
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '남은 사진 ${_controller.remainingCount}장',
                style: theme.textTheme.titleMedium,
              ),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }

  Widget _buildImageContent(ThemeData theme, ImageResponse image, String url) {
    return Dismissible(
      key: ValueKey(image.id),
      direction: DismissDirection.horizontal,
      background: _buildDismissBackground(
        alignment: Alignment.centerLeft,
        color: Colors.red.withOpacity(0.2),
        icon: Icons.delete_outline,
        label: '휴지통으로',
        labelColor: Colors.red.shade700,
      ),
      secondaryBackground: _buildDismissBackground(
        alignment: Alignment.centerRight,
        color: Colors.green.withOpacity(0.2),
        icon: Icons.bookmark_added_outlined,
        label: '남기기',
        labelColor: Colors.green.shade700,
      ),
      confirmDismiss: (direction) async => !_isProcessing,
      onDismissed: (direction) {
        final keep = direction == DismissDirection.endToStart;
        _handleSwipe(keep);
      },
      child: Stack(
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: url.isNotEmpty
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.photo, size: 64),
                      )
                    : const Icon(Icons.photo, size: 64),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Chip(
              label: Text(
                '#${image.id}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              backgroundColor: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _controller.loadImages,
              child: const Text('다시 불러오기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
    required Color labelColor,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: color,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: labelColor),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
