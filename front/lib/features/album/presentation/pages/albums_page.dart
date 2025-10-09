import 'package:flutter/material.dart';

class AlbumsPage extends StatelessWidget {
  const AlbumsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('앨범'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Implement create new album action
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle(icon: Icons.auto_awesome, title: 'AI 제안 앨범'),
          const SizedBox(height: 12),
          const _AlbumCard(
            albumName: '2024년 제주도 여행',
            photoCount: 23,
            duration: '3일간',
            tags: ['#바다', '#여행'],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(icon: Icons.collections, title: '내 앨범'),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2, // Adjust aspect ratio for better layout
            children: const [
              _AlbumCard(albumName: '가족 사진 모음', photoCount: 156),
              _AlbumCard(albumName: '친구들과', photoCount: 88),
              _AlbumCard(albumName: '맛집 탐방', photoCount: 210),
              // Add more albums as needed
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: Colors.black54, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final String albumName;
  final int photoCount;
  final String? duration;
  final List<String>? tags;

  const _AlbumCard({
    required this.albumName,
    required this.photoCount,
    this.duration,
    this.tags,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1.0, // Square aspect ratio for the image placeholder
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            // You can add a cover image here
          ),
        ),
        const SizedBox(height: 8),
        Text(albumName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('$photoCount장', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            if (duration != null)
              Text(' · $duration', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        if (tags != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(tags!.join(' '), style: const TextStyle(color: Colors.blue, fontSize: 12)),
          ),
      ],
    );
  }
}
