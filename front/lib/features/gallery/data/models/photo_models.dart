/// Represents a tag attached to a photo
class PhotoTag {
  final String id;
  final String name;
  final TagType type;

  const PhotoTag({
    required this.id,
    required this.name,
    required this.type,
  });

  factory PhotoTag.fromMap(Map<String, dynamic> map) {
    return PhotoTag(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: TagType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TagType.system,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoTag &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PhotoTag(id: $id, name: $name, type: $type)';
}

enum TagType {
  user,   // 사용자가 추가한 태그
  system, // AI/시스템이 자동으로 생성한 태그
}

/// Represents photo metadata from backend
class PhotoMetadata {
  final String? location;
  final String? camera;
  final String? resolution;
  final List<PhotoTag> userTags;
  final List<PhotoTag> systemTags;
  final Map<String, dynamic>? additionalInfo;

  const PhotoMetadata({
    this.location,
    this.camera,
    this.resolution,
    this.userTags = const [],
    this.systemTags = const [],
    this.additionalInfo,
  });

  factory PhotoMetadata.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const PhotoMetadata();
    }

    final userTagsList = (map['userTags'] as List<dynamic>?)
        ?.map((tag) => PhotoTag.fromMap(tag as Map<String, dynamic>))
        .toList() ?? [];

    final systemTagsList = (map['systemTags'] as List<dynamic>?)
        ?.map((tag) => PhotoTag.fromMap(tag as Map<String, dynamic>))
        .toList() ?? [];

    return PhotoMetadata(
      location: map['location'],
      camera: map['camera'],
      resolution: map['resolution'],
      userTags: userTagsList,
      systemTags: systemTagsList,
      additionalInfo: map['additionalInfo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'location': location,
      'camera': camera,
      'resolution': resolution,
      'userTags': userTags.map((tag) => tag.toMap()).toList(),
      'systemTags': systemTags.map((tag) => tag.toMap()).toList(),
      'additionalInfo': additionalInfo,
    };
  }

  PhotoMetadata copyWith({
    String? location,
    String? camera,
    String? resolution,
    List<PhotoTag>? userTags,
    List<PhotoTag>? systemTags,
    Map<String, dynamic>? additionalInfo,
  }) {
    return PhotoMetadata(
      location: location ?? this.location,
      camera: camera ?? this.camera,
      resolution: resolution ?? this.resolution,
      userTags: userTags ?? this.userTags,
      systemTags: systemTags ?? this.systemTags,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  /// Gets all tags (user + system)
  List<PhotoTag> get allTags => [...userTags, ...systemTags];

  @override
  String toString() =>
      'PhotoMetadata(location: $location, userTags: ${userTags.length}, systemTags: ${systemTags.length})';
}

/// 업로드 상태
enum UploadStatus {
  pending,    // 업로드 대기 중
  uploading,  // 업로드 중
  completed,  // 업로드 완료
  failed,     // 업로드 실패
}

/// Represents a single photo/image
class Photo {
  final String id;
  final String url; // 로컬 경로 또는 원격 URL
  final String? remoteUrl; // 백엔드 원본 이미지 URL
  final String? thumbnailUrl; // 백엔드 썸네일 URL
  final String? fileName;
  final DateTime? createdAt;
  final int? fileSize;
  final PhotoMetadata metadata;
  final UploadStatus uploadStatus;

  const Photo({
    required this.id,
    required this.url,
    this.remoteUrl,
    this.thumbnailUrl,
    this.fileName,
    this.createdAt,
    this.fileSize,
    this.metadata = const PhotoMetadata(),
    this.uploadStatus = UploadStatus.completed,
  });

  /// Creates a copy of this Photo with the given fields replaced
  Photo copyWith({
    String? id,
    String? url,
    String? remoteUrl,
    String? thumbnailUrl,
    String? fileName,
    DateTime? createdAt,
    int? fileSize,
    PhotoMetadata? metadata,
    UploadStatus? uploadStatus,
  }) {
    return Photo(
      id: id ?? this.id,
      url: url ?? this.url,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileName: fileName ?? this.fileName,
      createdAt: createdAt ?? this.createdAt,
      fileSize: fileSize ?? this.fileSize,
      metadata: metadata ?? this.metadata,
      uploadStatus: uploadStatus ?? this.uploadStatus,
    );
  }

  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      id: map['id'] ?? '',
      url: map['url'] ?? '',
      remoteUrl: map['remoteUrl'],
      thumbnailUrl: map['thumbnailUrl'],
      fileName: map['fileName'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null,
      fileSize: map['fileSize'],
      metadata: PhotoMetadata.fromMap(map['metadata']),
      uploadStatus: map['uploadStatus'] != null
          ? UploadStatus.values.firstWhere(
              (e) => e.name == map['uploadStatus'],
              orElse: () => UploadStatus.completed,
            )
          : UploadStatus.completed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'remoteUrl': remoteUrl,
      'thumbnailUrl': thumbnailUrl,
      'fileName': fileName,
      'createdAt': createdAt?.toIso8601String(),
      'fileSize': fileSize,
      'metadata': metadata.toMap(),
      'uploadStatus': uploadStatus.name,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Photo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          url == other.url;

  @override
  int get hashCode => id.hashCode ^ url.hashCode;

  @override
  String toString() => 'Photo(id: $id, fileName: $fileName, url: $url)';
}

/// Represents a section of photos grouped by date
class PhotoSection {
  final String date;
  final int imageCount;

  const PhotoSection({
    required this.date,
    required this.imageCount,
  });

  /// Creates a copy of this PhotoSection with the given fields replaced
  PhotoSection copyWith({
    String? date,
    int? imageCount,
  }) {
    return PhotoSection(
      date: date ?? this.date,
      imageCount: imageCount ?? this.imageCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoSection &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          imageCount == other.imageCount;

  @override
  int get hashCode => date.hashCode ^ imageCount.hashCode;

  @override
  String toString() => 'PhotoSection(date: $date, imageCount: $imageCount)';
}

/// Represents the result of an upload operation
class UploadResult {
  final bool success;
  final int totalFiles;
  final int successCount;
  final int failedCount;
  final List<String> failedFiles;
  final bool cancelled;

  const UploadResult({
    required this.success,
    required this.totalFiles,
    required this.successCount,
    required this.failedCount,
    required this.failedFiles,
    this.cancelled = false,
  });

  factory UploadResult.fromMap(Map<String, dynamic> map) {
    return UploadResult(
      success: map['success'] ?? false,
      totalFiles: map['totalFiles'] ?? 0,
      successCount: map['successCount'] ?? 0,
      failedCount: map['failedCount'] ?? 0,
      failedFiles: List<String>.from(map['failedFiles'] ?? []),
      cancelled: map['cancelled'] ?? false,
    );
  }

  @override
  String toString() =>
      'UploadResult(success: $success, totalFiles: $totalFiles, successCount: $successCount, failedCount: $failedCount, cancelled: $cancelled)';
}