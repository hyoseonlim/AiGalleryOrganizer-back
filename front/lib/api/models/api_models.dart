/// OpenAPI 스펙에 따른 전체 API 모델 정의
library;

// ============================================================================
// Album Models
// ============================================================================

class AlbumCreate {
  final String name;
  final String? description;
  final int? coverImageId;
  final List<int>? imageIds;

  const AlbumCreate({
    required this.name,
    this.description,
    this.coverImageId,
    this.imageIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (description != null) 'description': description,
      if (coverImageId != null) 'cover_image_id': coverImageId,
      if (imageIds != null) 'image_ids': imageIds,
    };
  }
}

class AlbumUpdate {
  final String? name;
  final String? description;
  final int? coverImageId;

  const AlbumUpdate({
    this.name,
    this.description,
    this.coverImageId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (coverImageId != null) 'cover_image_id': coverImageId,
    };
  }
}

class AlbumResponse {
  final int albumId;
  final String name;
  final String? description;
  final DateTime createdAt;
  final int? coverImageId;
  final ImageResponse? coverImage;
  final int imageCount;

  const AlbumResponse({
    required this.albumId,
    required this.name,
    this.description,
    required this.createdAt,
    this.coverImageId,
    this.coverImage,
    this.imageCount = 0,
  });

  factory AlbumResponse.fromMap(Map<String, dynamic> map) {
    return AlbumResponse(
      albumId: map['album_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      coverImageId: map['cover_image_id'] as int?,
      coverImage: map['cover_image'] != null
          ? ImageResponse.fromMap(map['cover_image'] as Map<String, dynamic>)
          : null,
      imageCount: map['image_count'] as int? ?? 0,
    );
  }
}

class AlbumImageRequest {
  final List<int> imageIds;

  const AlbumImageRequest({required this.imageIds});

  Map<String, dynamic> toMap() {
    return {'image_ids': imageIds};
  }
}

// ============================================================================
// Category Models
// ============================================================================

class CategoryCreate {
  final String name;

  const CategoryCreate({required this.name});

  Map<String, dynamic> toMap() {
    return {'name': name};
  }
}

class CategoryUpdate {
  final String? name;

  const CategoryUpdate({this.name});

  Map<String, dynamic> toMap() {
    return {
      if (name != null) 'name': name,
    };
  }
}

class CategoryResponse {
  final int id;
  final String name;

  const CategoryResponse({
    required this.id,
    required this.name,
  });

  factory CategoryResponse.fromMap(Map<String, dynamic> map) {
    return CategoryResponse(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }
}

// ============================================================================
// Tag Models
// ============================================================================

class TagCreate {
  final String name;
  final int categoryId;

  const TagCreate({
    required this.name,
    required this.categoryId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category_id': categoryId,
    };
  }
}

class TagUpdate {
  final String? name;
  final int? categoryId;

  const TagUpdate({
    this.name,
    this.categoryId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (name != null) 'name': name,
      if (categoryId != null) 'category_id': categoryId,
    };
  }
}

class TagResponse {
  final int id;
  final String name;
  final int? userId;
  final int categoryId;
  final CategoryResponse category;

  const TagResponse({
    required this.id,
    required this.name,
    this.userId,
    required this.categoryId,
    required this.category,
  });

  factory TagResponse.fromMap(Map<String, dynamic> map) {
    return TagResponse(
      id: map['id'] as int,
      name: map['name'] as String,
      userId: map['user_id'] as int?,
      categoryId: map['category_id'] as int,
      category: CategoryResponse.fromMap(map['category'] as Map<String, dynamic>),
    );
  }
}

class ImageTagRequest {
  final List<String> tagNames;

  const ImageTagRequest({required this.tagNames});

  Map<String, dynamic> toMap() {
    return {'tag_names': tagNames};
  }
}

// ============================================================================
// Similar Group Models
// ============================================================================

class SimilarGroupResponse {
  final int id;
  final String? name;
  final int imageCount;
  final DateTime createdAt;
  final int? bestImageId;
  final ImageResponse? bestImage;

  const SimilarGroupResponse({
    required this.id,
    this.name,
    required this.imageCount,
    required this.createdAt,
    this.bestImageId,
    this.bestImage,
  });

  factory SimilarGroupResponse.fromMap(Map<String, dynamic> map) {
    return SimilarGroupResponse(
      id: map['id'] as int,
      name: map['name'] as String?,
      imageCount: map['image_count'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      bestImageId: map['best_image_id'] as int?,
      bestImage: map['best_image'] != null
          ? ImageResponse.fromMap(map['best_image'] as Map<String, dynamic>)
          : null,
    );
  }
}

class SimilarGroupConfirmRequest {
  final List<int> imageIdsToDelete;

  const SimilarGroupConfirmRequest({
    this.imageIdsToDelete = const [],
  });

  Map<String, dynamic> toMap() {
    return {'image_ids_to_delete': imageIdsToDelete};
  }
}

// ============================================================================
// User Models
// ============================================================================

class UserCreate {
  final String email;
  final String username;
  final String password;

  const UserCreate({
    required this.email,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'password': password,
    };
  }
}

class UserUpdate {
  final String? username;
  final bool? isActive;

  const UserUpdate({
    this.username,
    this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      if (username != null) 'username': username,
      if (isActive != null) 'is_active': isActive,
    };
  }
}

class UserResponse {
  final int id;
  final String email;
  final String username;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserResponse({
    required this.id,
    required this.email,
    required this.username,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserResponse.fromMap(Map<String, dynamic> map) {
    return UserResponse(
      id: map['id'] as int,
      email: map['email'] as String,
      username: map['username'] as String,
      isActive: map['is_active'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}

// ============================================================================
// Auth Models
// ============================================================================

class Token {
  final String accessToken;
  final String tokenType;
  final String refreshToken;

  const Token({
    required this.accessToken,
    required this.tokenType,
    required this.refreshToken,
  });

  factory Token.fromMap(Map<String, dynamic> map) {
    return Token(
      accessToken: map['access_token'] as String,
      tokenType: map['token_type'] as String,
      refreshToken: map['refresh_token'] as String,
    );
  }
}

// ============================================================================
// Image Analysis Models
// ============================================================================

class ImageAnalysisResult {
  final String tagName;
  final double probability;
  final String? category;
  final double? categoryProbability;
  final double? qualityScore;
  final List<double>? featureVector;
  final String? imageUrl;

  const ImageAnalysisResult({
    required this.tagName,
    required this.probability,
    this.category,
    this.categoryProbability,
    this.qualityScore,
    this.featureVector,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'tag_name': tagName,
      'probability': probability,
      if (category != null) 'category': category,
      if (categoryProbability != null) 'category_probability': categoryProbability,
      if (qualityScore != null) 'quality_score': qualityScore,
      if (featureVector != null) 'feature_vector': featureVector,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }
}

// Image Upload Models
class ImageHashPayload {
  final String clientId;
  final String hash;

  const ImageHashPayload({
    required this.clientId,
    required this.hash,
  });

  Map<String, dynamic> toMap() {
    return {
      'client_id': clientId,
      'hash': hash,
    };
  }

  factory ImageHashPayload.fromMap(Map<String, dynamic> map) {
    return ImageHashPayload(
      clientId: map['client_id'] as String,
      hash: map['hash'] as String,
    );
  }
}

class ImageUploadRequest {
  final List<ImageHashPayload> images;

  const ImageUploadRequest({
    required this.images,
  });

  Map<String, dynamic> toMap() {
    return {
      'images': images.map((e) => e.toMap()).toList(),
    };
  }
}

class UploadInstruction {
  final String clientId;
  final int imageId;
  final String presignedUrl;

  const UploadInstruction({
    required this.clientId,
    required this.imageId,
    required this.presignedUrl,
  });

  factory UploadInstruction.fromMap(Map<String, dynamic> map) {
    return UploadInstruction(
      clientId: map['client_id'] as String,
      imageId: map['image_id'] as int,
      presignedUrl: map['presigned_url'] as String,
    );
  }
}

class DuplicateInfo {
  final String clientId;
  final int existingImageId;

  const DuplicateInfo({
    required this.clientId,
    required this.existingImageId,
  });

  factory DuplicateInfo.fromMap(Map<String, dynamic> map) {
    return DuplicateInfo(
      clientId: map['client_id'] as String,
      existingImageId: map['existing_image_id'] as int,
    );
  }
}

class PresignedUrlResponse {
  final List<UploadInstruction> uploads;
  final List<DuplicateInfo> duplicates;

  const PresignedUrlResponse({
    required this.uploads,
    required this.duplicates,
  });

  factory PresignedUrlResponse.fromMap(Map<String, dynamic> map) {
    return PresignedUrlResponse(
      uploads: (map['uploads'] as List)
          .map((e) => UploadInstruction.fromMap(e as Map<String, dynamic>))
          .toList(),
      duplicates: (map['duplicates'] as List)
          .map((e) => DuplicateInfo.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class UploadCompleteResponse {
  final int imageId;
  final String status;
  final String hash;

  const UploadCompleteResponse({
    required this.imageId,
    required this.status,
    required this.hash,
  });

  factory UploadCompleteResponse.fromMap(Map<String, dynamic> map) {
    return UploadCompleteResponse(
      imageId: map['image_id'] as int,
      status: map['status'] as String,
      hash: map['hash'] as String,
    );
  }
}

class ImageMetadata {
  final int width;
  final int height;
  final int? fileSize;
  final DateTime? dateTaken;
  final String? mimeType;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? exifData;

  const ImageMetadata({
    required this.width,
    required this.height,
    this.fileSize,
    this.dateTaken,
    this.mimeType,
    this.latitude,
    this.longitude,
    this.exifData,
  });

  Map<String, dynamic> toMap() {
    return {
      'width': width,
      'height': height,
      if (fileSize != null) 'fileSize': fileSize,
      if (dateTaken != null) 'dateTaken': dateTaken!.toIso8601String(),
      if (mimeType != null) 'mime_type': mimeType,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (exifData != null) 'exifData': exifData,
    };
  }

  factory ImageMetadata.fromMap(Map<String, dynamic> map) {
    return ImageMetadata(
      width: map['width'] as int,
      height: map['height'] as int,
      fileSize: map['fileSize'] as int?,
      dateTaken: map['dateTaken'] != null
          ? DateTime.parse(map['dateTaken'] as String)
          : null,
      mimeType: map['mime_type'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      exifData: map['exifData'] as Map<String, dynamic>?,
    );
  }
}

class ImageViewableResponse {
  final int imageId;
  final String url;

  const ImageViewableResponse({
    required this.imageId,
    required this.url,
  });

  factory ImageViewableResponse.fromMap(Map<String, dynamic> map) {
    return ImageViewableResponse(
      imageId: map['image_id'] as int,
      url: map['url'] as String,
    );
  }
}

// Import ImageResponse from photo_models.dart
// This is a placeholder - actual import should be done in the file that uses these models
class ImageResponse {
  final int id;
  final String? url;
  final DateTime uploadedAt;
  final String status;

  const ImageResponse({
    required this.id,
    this.url,
    required this.uploadedAt,
    required this.status,
  });

  factory ImageResponse.fromMap(Map<String, dynamic> map) {
    return ImageResponse(
      id: map['id'] as int,
      url: map['url'] as String?,
      uploadedAt: DateTime.parse(map['uploaded_at'] as String),
      status: map['ai_processing_status'] as String? ?? 'PENDING',
    );
  }
}
