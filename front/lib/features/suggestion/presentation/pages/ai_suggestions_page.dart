import 'package:flutter/material.dart';

class AiSuggestionsPage extends StatelessWidget {
  const AiSuggestionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 정리 제안'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 24),
          _buildSuggestionGroup(
            title: '중복 사진',
            subtitle: '5그룹, 15장',
            savingSize: '15 MB 절약 가능',
            imageCount: 3,
            isDuplicate: true,
          ),
          const SizedBox(height: 24),
          _buildSuggestionGroup(
            title: '유사한 사진 그룹',
            subtitle: '8그룹, 24장',
            albumTitle: '제주도 여행',
            tagString: '#바다 #여행 #여름',
            imageCount: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      color: Colors.blue.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('절약 가능: 125 MB', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            SizedBox(height: 8),
            Text('45장의 정리 가능한 사진 발견', style: TextStyle(fontSize: 14, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionGroup({
    required String title,
    required String subtitle,
    String? savingSize,
    String? albumTitle,
    String? tagString,
    required int imageCount,
    bool isDuplicate = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(isDuplicate ? Icons.copy : Icons.photo_library_outlined, color: Colors.orangeAccent, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 28, top: 4, bottom: 12),
          child: Text(subtitle, style: const TextStyle(color: Colors.grey)),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: imageCount,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
          ),
        ),
        if (albumTitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
            child: Text(albumTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        if (tagString != null)
          Text(tagString, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                child: Text(isDuplicate ? '모두 삭제' : '앨범 저장'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextButton(
                onPressed: () {},
                child: const Text('무시', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
