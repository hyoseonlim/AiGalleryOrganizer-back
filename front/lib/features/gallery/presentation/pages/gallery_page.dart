import 'package:flutter/material.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  // Mock data for photos, grouped by date
  final Map<String, int> _photoSections = {
    '2025년 1월 15일': 3,
    '2025년 1월 14일': 6,
    '2025년 1월 12일': 5,
  };

  bool _isMultiSelectMode = false;
  final Set<String> _selectedPhotos = {}; // Using a unique ID for each photo

  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedPhotos.clear();
      }
    });
  }

  void _onPhotoTap(String photoId) {
    if (_isMultiSelectMode) {
      setState(() {
        if (_selectedPhotos.contains(photoId)) {
          _selectedPhotos.remove(photoId);
        } else {
          _selectedPhotos.add(photoId);
        }
      });
    }
  }

  void _onPhotoLongPress(String photoId) {
    if (!_isMultiSelectMode) {
      _toggleMultiSelectMode();
      _onPhotoTap(photoId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: ListView.builder(
        itemCount: _photoSections.length,
        itemBuilder: (context, index) {
          final date = _photoSections.keys.elementAt(index);
          final imageCount = _photoSections.values.elementAt(index);
          return _DateSection(
            date: date,
            imageCount: imageCount,
            selectedPhotos: _selectedPhotos,
            isMultiSelectMode: _isMultiSelectMode,
            onPhotoTap: _onPhotoTap,
            onPhotoLongPress: _onPhotoLongPress,
          );
        },
      ),
      floatingActionButton: _isMultiSelectMode
          ? null
          : FloatingActionButton(
              onPressed: () {
                // TODO: Implement add photo action
              },
              child: const Icon(Icons.add),
            ),
    );
  }

  AppBar _buildAppBar() {
    if (_isMultiSelectMode) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _toggleMultiSelectMode,
        ),
        title: Text('${_selectedPhotos.length}개 선택'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share action for selected photos
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              // TODO: Implement delete action for selected photos
            },
          ),
        ],
      );
    }

    return AppBar(
      title: const Text('AI Gallery'),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'select') {
              _toggleMultiSelectMode();
            }
            // TODO: Handle other options like sort
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'sort',
              child: Text('정렬'),
            ),
            const PopupMenuItem<String>(
              value: 'select',
              child: Text('선택'),
            ),
          ],
        ),
      ],
    );
  }
}

class _DateSection extends StatelessWidget {
  final String date;
  final int imageCount;
  final Set<String> selectedPhotos;
  final bool isMultiSelectMode;
  final Function(String) onPhotoTap;
  final Function(String) onPhotoLongPress;

  const _DateSection({
    required this.date,
    required this.imageCount,
    required this.selectedPhotos,
    required this.isMultiSelectMode,
    required this.onPhotoTap,
    required this.onPhotoLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            date,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2.0,
            mainAxisSpacing: 2.0,
          ),
          itemCount: imageCount,
          itemBuilder: (context, index) {
            final photoId = '$date-$index'; // Unique ID for each photo
            final isSelected = selectedPhotos.contains(photoId);
            return _PhotoItem(
              photoId: photoId,
              isSelected: isSelected,
              isMultiSelectMode: isMultiSelectMode,
              onTap: () => onPhotoTap(photoId),
              onLongPress: () => onPhotoLongPress(photoId),
            );
          },
        ),
      ],
    );
  }
}

class _PhotoItem extends StatelessWidget {
  final String photoId;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PhotoItem({
    required this.photoId,
    required this.isSelected,
    required this.isMultiSelectMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.grey[300],
            // Placeholder for the image
          ),
          if (isMultiSelectMode)
            Positioned(
              top: 4,
              right: 4,
              child: Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? Theme.of(context).primaryColor : Colors.white70,
              ),
            ),
          if (isSelected)
            Container(
              color: Colors.black.withOpacity(0.3),
            ),
        ],
      ),
    );
  }
}
