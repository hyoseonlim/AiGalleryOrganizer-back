import 'package:front/features/gallery/data/models/photo_models.dart';

class SimilarGroup {
  final int id;
  final String? name;
  final int imageCount;
  final DateTime createdAt;
  final int? bestImageId;
  final ImageResponse? bestImage;

  const SimilarGroup({
    required this.id,
    this.name,
    required this.imageCount,
    required this.createdAt,
    this.bestImageId,
    this.bestImage,
  });

  factory SimilarGroup.fromMap(Map<String, dynamic> map) {
    return SimilarGroup(
      id: map['id'] ?? map['group_id'] ?? 0,
      name: map['name'] as String?,
      imageCount: map['image_count'] ?? map['imageCount'] ?? 0,
      createdAt: DateTime.parse(
        map['created_at'] ??
            map['createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
      bestImageId: map['best_image_id'] ?? map['bestImageId'],
      bestImage: map['best_image'] != null
          ? ImageResponse.fromMap(map['best_image'] as Map<String, dynamic>)
          : null,
    );
  }

  SimilarGroup copyWith({
    int? id,
    String? name,
    int? imageCount,
    DateTime? createdAt,
    int? bestImageId,
    ImageResponse? bestImage,
  }) {
    return SimilarGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      imageCount: imageCount ?? this.imageCount,
      createdAt: createdAt ?? this.createdAt,
      bestImageId: bestImageId ?? this.bestImageId,
      bestImage: bestImage ?? this.bestImage,
    );
  }

  String get displayTitle => name?.isNotEmpty == true ? name! : '그룹 #$id';

  int get removableCount => imageCount > 0 ? imageCount - 1 : 0;
}

class SimilarGroupImage {
  final int id;
  final String? url;
  final DateTime uploadedAt;
  final AIProcessingStatus status;

  const SimilarGroupImage({
    required this.id,
    this.url,
    required this.uploadedAt,
    required this.status,
  });

  factory SimilarGroupImage.fromMap(Map<String, dynamic> map) {
    final response = ImageResponse.fromMap(map);
    return SimilarGroupImage(
      id: response.id,
      url: response.url,
      uploadedAt: response.uploadedAt,
      status: response.status,
    );
  }
}
