import 'package:flutter/material.dart';
import 'package:front/api/vizota_api.dart';
import '../../domain/suggestion_service.dart';

class AiSuggestionsPage extends StatefulWidget {
class AiSuggestionsPage extends StatefulWidget {
  const AiSuggestionsPage({super.key});

  @override
  State<AiSuggestionsPage> createState() => _AiSuggestionsPageState();
}

class _AiSuggestionsPageState extends State<AiSuggestionsPage> {
  final _suggestionService = SuggestionService();

  List<SimilarGroupResponse>? _groups;
  Map<int, List<ImageResponse>> _groupImages = {};
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final groups = await _suggestionService.getSuggestedGroups();
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '제안을 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadGroupImages(int groupId) async {
    if (_groupImages.containsKey(groupId)) return;

    try {
      final images = await _suggestionService.getImagesForGroup(groupId);
      setState(() {
        _groupImages[groupId] = images;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지를 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _handleConfirmBest(int groupId) async {
    try {
      await _suggestionService.confirmBestImage(groupId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('대표 이미지만 남기고 삭제했습니다')),
        );
        _loadSuggestions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }

  Future<void> _handleReject(int groupId) async {
    try {
      await _suggestionService.rejectSuggestion(groupId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('제안을 무시했습니다')),
        );
        _loadSuggestions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 정리 제안'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadSuggestions,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _scanForSimilarImages,
        icon: const Icon(Icons.search),
        label: const Text('유사 이미지 찾기'),
      ),
    );
  }

  Future<void> _scanForSimilarImages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _suggestionService.findAndGroupImages();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('유사 이미지 그룹을 찾았습니다')),
        );
        _loadSuggestions();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('스캔 실패: $e')),
        );
      }
    }
  }

  Widget _buildBody() {
    if (_isLoading && _groups == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSuggestions,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_groups == null || _groups!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '제안된 그룹이 없습니다',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '하단의 버튼을 눌러 유사 이미지를 검색하세요',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 24),
        ..._groups!.map((group) => Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: _buildSuggestionGroup(group),
        )),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final totalGroups = _groups?.length ?? 0;
    final totalImages = _groups?.fold<int>(0, (sum, g) => sum + g.imageCount) ?? 0;

    return Card(
      color: Colors.blue.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$totalGroups개 그룹 발견',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$totalImages장의 유사한 사진',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionGroup(SimilarGroupResponse group) {
    final images = _groupImages[group.id];

    // 처음 보이면 이미지 로드
    if (images == null) {
      _loadGroupImages(group.id);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.photo_library_outlined, color: Colors.orangeAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              '유사 그룹 #${group.id}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 28, top: 4, bottom: 12),
          child: Text(
            '${group.imageCount}장의 유사한 사진',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        SizedBox(
          height: 100,
          child: images == null
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final image = images[index];
                    return AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: image.url != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  image.url!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(Icons.broken_image, color: Colors.grey[600]),
                                    );
                                  },
                                ),
                              )
                            : Center(
                                child: Icon(Icons.image, color: Colors.grey[600]),
                              ),
                      ),
                    );
                  },
                ),
        ),
        if (group.bestImageId != null)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Text(
              '대표 이미지: #${group.bestImageId}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _handleConfirmBest(group.id),
                child: const Text('대표만 남기기'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextButton(
                onPressed: () => _handleReject(group.id),
                child: const Text('무시', style: TextStyle(color: Colors.grey)),
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
