import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:front/features/gallery/data/models/photo_models.dart';
import '../../../gallery/data/api/gallery_api_factory.dart';
import '../../data/models/similar_group_models.dart';
import '../../domain/ai_suggestion_service.dart';
import '../controllers/ai_suggestions_controller.dart';

class AiSuggestionsPage extends StatefulWidget {
  const AiSuggestionsPage({super.key});

  @override
  State<AiSuggestionsPage> createState() => _AiSuggestionsPageState();
}

class _AiSuggestionsPageState extends State<AiSuggestionsPage> {
  late final AiSuggestionsController _controller;

  @override
  void initState() {
    super.initState();
    final factory = GalleryApiFactory.instance;
    final service = AiSuggestionService(factory.suggestion);
    _controller = AiSuggestionsController(service)
      ..addListener(_onControllerChanged)
      ..loadSuggestions();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 정리 제안'),
        actions: [
          IconButton(
            onPressed: _controller.isRefreshing
                ? null
                : () async {
                    await _controller.refreshSuggestions();
                    if (mounted && _controller.errorMessage != null) {
                      _showSnackBar(_controller.errorMessage!);
                    }
                  },
            icon: _controller.isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.errorMessage != null && _controller.groups.isEmpty) {
      return _buildErrorState(_controller.errorMessage!);
    }

    if (_controller.groups.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _controller.refreshSuggestions,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          ..._controller.groups.map(_buildGroupCard),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalGroups = _controller.groups.length;
    final totalImages = _controller.totalImages;
    final removable = _controller.removableImages;
    final formatter = NumberFormat.compact();

    return Card(
      color: Colors.blue.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '총 ${formatter.format(totalGroups)}개의 제안',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${formatter.format(removable)}장의 사진을 정리하면 '
              '약 ${(removable * 2)}MB를 절약할 수 있어요.',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _controller.potentialSavingRatio.clamp(0, 1),
              backgroundColor: Colors.white,
              color: Colors.blue,
              minHeight: 6,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(SimilarGroup group) {
    final createdAt = DateFormat('yyyy.MM.dd').format(group.createdAt);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ExpansionTile(
        key: ValueKey('group_${group.id}'),
        title: Text(group.displayTitle),
        subtitle: Text('이미지 ${group.imageCount}장 • 생성일 $createdAt'),
        trailing: Chip(
          label: Text('정리 가능 ${group.removableCount}장'),
          backgroundColor: Colors.orange.shade50,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FutureBuilder<List<ImageResponse>>(
              future: _controller.loadGroupImages(group.id),
              initialData: _controller.cachedGroupImages(group.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    (snapshot.data == null || snapshot.data!.isEmpty)) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('이미지를 불러오지 못했습니다: ${snapshot.error}'),
                      TextButton(
                        onPressed: () => setState(() {}),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  );
                }

                final images = snapshot.data ?? [];
                if (images.isEmpty) {
                  return const Text('이미지를 불러올 수 없습니다.');
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageGrid(group.id, images),
                    const SizedBox(height: 12),
                    _buildActionRow(group, images),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(int groupId, List<ImageResponse> images) {
    final selected = _controller.selectedForDeletion(groupId);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: images.map<Widget>((image) {
        final isSelected = selected.contains(image.id);
        return GestureDetector(
          onTap: () => _controller.toggleSelection(groupId, image.id),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: Colors.grey.shade200,
                  width: 90,
                  height: 90,
                  child: image.url != null && image.url!.isNotEmpty
                      ? Image.network(
                          image.url!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.photo, size: 32),
                        )
                      : const Icon(Icons.photo, size: 32),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white,
                  child: Icon(
                    isSelected ? Icons.check : Icons.check_circle_outline,
                    color: isSelected ? Colors.white : Colors.grey,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionRow(SimilarGroup group, List<ImageResponse> images) {
    final selection = _controller.selectedForDeletion(group.id);
    final hasSelection = selection.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final success = await _controller.confirmBest(group.id);
                  if (!mounted) return;
                  if (success) {
                    _showSnackBar('대표 이미지만 남겼습니다.');
                  } else if (_controller.errorMessage != null) {
                    _showSnackBar(_controller.errorMessage!);
                  }
                },
                icon: const Icon(Icons.star),
                label: const Text('대표만 남기기'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: hasSelection
                    ? () async {
                        final success = await _controller.confirmSelection(
                          group.id,
                        );
                        if (!mounted) return;
                        if (success) {
                          _showSnackBar('선택한 이미지를 정리했습니다.');
                        } else if (_controller.errorMessage != null) {
                          _showSnackBar(_controller.errorMessage!);
                        }
                      }
                    : null,
                icon: const Icon(Icons.delete_outline),
                label: Text(
                  hasSelection ? '선택 삭제 (${selection.length})' : '삭제할 이미지 선택',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () async {
              final success = await _controller.rejectGroup(group.id);
              if (!mounted) return;
              if (success) {
                _showSnackBar('제안을 숨겼습니다.');
              } else if (_controller.errorMessage != null) {
                _showSnackBar(_controller.errorMessage!);
              }
            },
            icon: const Icon(Icons.close),
            label: const Text('제안 거절'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.celebration, size: 60, color: Colors.blue.shade300),
            const SizedBox(height: 16),
            const Text(
              '지금은 분석 결과가 없습니다.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('필요하면 새로 제안을 생성해보세요.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await _controller.refreshSuggestions();
                if (mounted && _controller.errorMessage != null) {
                  _showSnackBar(_controller.errorMessage!);
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('AI 제안 새로 생성'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _controller.loadSuggestions,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
