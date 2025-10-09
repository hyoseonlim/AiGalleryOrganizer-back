import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isAndMode = true; // For AND/OR toggle

  // Mock data
  final List<String> _recentSearches = ['고양이', '제주도 여행', '2024년 여름'];
  final List<String> _popularTags = ['바다', '가족', '음식', '여행', '하늘', '강아지'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('검색'),
        // The back arrow is automatically handled by the Navigator if pushed
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSearchBar(),
          const SizedBox(height: 24),
          _buildQuickFilters(),
          const SizedBox(height: 32),
          _buildSectionTitle(title: '최근 검색'),
          _buildRecentSearches(),
          const SizedBox(height: 32),
          _buildSectionTitle(title: '인기 태그'),
          _buildPopularTags(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        hintText: '사진 검색...',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(30.0)),
        ),
      ),
      onSubmitted: (value) {
        // TODO: Implement search logic
      },
    );
  }

  Widget _buildQuickFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('빠른 필터', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FilterChip(label: const Text('날짜'), onSelected: (s) {}),
            FilterChip(label: const Text('위치'), onSelected: (s) {}),
            FilterChip(label: const Text('태그'), onSelected: (s) {}),
            // AND/OR Toggle
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('AND')),
                ButtonSegment(value: false, label: Text('OR')),
              ],
              selected: {_isAndMode},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _isAndMode = newSelection.first;
                });
              },
              style: SegmentedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
              )
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle({required String title}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      children: _recentSearches.map((term) => ListTile(
        leading: const Icon(Icons.history),
        title: Text(term),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: () {
            setState(() {
              _recentSearches.remove(term);
            });
          },
        ),
        onTap: () => _searchController.text = term,
        contentPadding: EdgeInsets.zero,
      )).toList(),
    );
  }

  Widget _buildPopularTags() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: _popularTags.map((tag) => ActionChip(
        label: Text(tag),
        onPressed: () {
          // TODO: Add tag to search query
        },
      )).toList(),
    );
  }
}
