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
  final String? fileName;
  final DateTime? createdAt;
  final int? fileSize;
  final PhotoMetadata metadata;
  final UploadStatus uploadStatus;

  const Photo({
    required this.id,
    required this.url,
    this.remoteUrl,
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

/// Represents a presigned URL for uploading an image
class PresignedUrlData {
  final int imageId;
  final String presignedUrl;

  const PresignedUrlData({
    required this.imageId,
    required this.presignedUrl,
  });

  factory PresignedUrlData.fromMap(Map<String, dynamic> map) {
    return PresignedUrlData(
      imageId: map['image_id'] ?? 0,
      presignedUrl: map['presigned_url'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'image_id': imageId,
      'presigned_url': presignedUrl,
    };
  }

  @override
  String toString() => 'PresignedUrlData(imageId: $imageId, presignedUrl: $presignedUrl)';
}

/// Represents the response from presigned URL request
class PresignedUrlResponse {
  final List<PresignedUrlData> presignedUrls;

  const PresignedUrlResponse({
    required this.presignedUrls,
  });

  factory PresignedUrlResponse.fromMap(Map<String, dynamic> map) {
    final urls = (map['presigned_urls'] as List<dynamic>?)
        ?.map((item) => PresignedUrlData.fromMap(item as Map<String, dynamic>))
        .toList() ?? [];

    return PresignedUrlResponse(
      presignedUrls: urls,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'presigned_urls': presignedUrls.map((url) => url.toMap()).toList(),
    };
  }

  @override
  String toString() => 'PresignedUrlResponse(presignedUrls: ${presignedUrls.length})';
}

/// Represents a validation error detail from API
class ValidationErrorDetail {
  final List<dynamic> loc;
  final String msg;
  final String type;

  const ValidationErrorDetail({
    required this.loc,
    required this.msg,
    required this.type,
  });

  factory ValidationErrorDetail.fromMap(Map<String, dynamic> map) {
    return ValidationErrorDetail(
      loc: List<dynamic>.from(map['loc'] ?? []),
      msg: map['msg'] ?? '',
      type: map['type'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'loc': loc,
      'msg': msg,
      'type': type,
    };
  }

  @override
  String toString() => 'ValidationErrorDetail(loc: $loc, msg: $msg, type: $type)';
}

/// Represents the response from upload/complete endpoint
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
      imageId: map['image_id'] ?? 0,
      status: map['status'] ?? '',
      hash: map['hash'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'image_id': imageId,
      'status': status,
      'hash': hash,
    };
  }

  @override
  String toString() => 'UploadCompleteResponse(imageId: $imageId, status: $status, hash: $hash)';
}

/// AI 처리 상태
enum AIProcessingStatus {
  pending,
  processing,
  completed,
  failed;

  factory AIProcessingStatus.fromString(String value) {
    return AIProcessingStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => AIProcessingStatus.pending,
    );
  }

  String toApiString() => name.toUpperCase();
}

/// 백엔드 API 이미지 응답 모델
class ImageResponse {
  final int id;
  final int userId;
  final String s3Key;
  final String hash;
  final int fileSize;
  final AIProcessingStatus status;
  final DateTime uploadedAt;
  final DateTime? deletedAt;
  final String? aiDescription;
  final List<String> aiTags;
  final Map<String, dynamic>? metadata;

  const ImageResponse({
    required this.id,
    required this.userId,
    required this.s3Key,
    required this.hash,
    required this.fileSize,
    required this.status,
    required this.uploadedAt,
    this.deletedAt,
    this.aiDescription,
    this.aiTags = const [],
    this.metadata,
  });

  factory ImageResponse.fromMap(Map<String, dynamic> map) {
    return ImageResponse(
      id: map['id'] ?? 0,
      userId: map['user_id'] ?? 0,
      s3Key: map['s3_key'] ?? '',
      hash: map['hash'] ?? '',
      fileSize: map['file_size'] ?? 0,
      status: AIProcessingStatus.fromString(map['status'] ?? 'PENDING'),
      uploadedAt: DateTime.parse(map['uploaded_at']),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
      aiDescription: map['ai_description'],
      aiTags: List<String>.from(map['ai_tags'] ?? []),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      's3_key': s3Key,
      'hash': hash,
      'file_size': fileSize,
      'status': status.toApiString(),
      'uploaded_at': uploadedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'ai_description': aiDescription,
      'ai_tags': aiTags,
      'metadata': metadata,
    };
  }

  /// ImageResponse를 Photo로 변환
  Photo toPhoto({String? viewUrl, String? localThumbnailPath}) {
    return Photo(
      id: id.toString(),
      url: localThumbnailPath ?? viewUrl ?? '',
      remoteUrl: viewUrl,
      fileName: s3Key.split('/').last,
      createdAt: uploadedAt,
      fileSize: fileSize,
      metadata: PhotoMetadata(
        systemTags: aiTags.map((tag) => PhotoTag(
          id: tag,
          name: tag,
          type: TagType.system,
        )).toList(),
        additionalInfo: metadata,
      ),
      uploadStatus: _mapAIStatusToUploadStatus(status),
    );
  }

  static UploadStatus _mapAIStatusToUploadStatus(AIProcessingStatus status) {
    switch (status) {
      case AIProcessingStatus.pending:
        return UploadStatus.pending;
      case AIProcessingStatus.processing:
        return UploadStatus.uploading;
      case AIProcessingStatus.completed:
        return UploadStatus.completed;
      case AIProcessingStatus.failed:
        return UploadStatus.failed;
    }
  }

  @override
  String toString() => 'ImageResponse(id: $id, s3Key: $s3Key, status: $status)';
}

/// 이미지 view URL 응답
class ImageViewableResponse {
  final String url;
  final DateTime expiresAt;

  const ImageViewableResponse({
    required this.url,
    required this.expiresAt,
  });

  factory ImageViewableResponse.fromMap(Map<String, dynamic> map) {
    return ImageViewableResponse(
      url: map['url'] ?? '',
      expiresAt: DateTime.parse(map['expires_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  @override
  String toString() => 'ImageViewableResponse(url: $url, expiresAt: $expiresAt)';
}

/// 이미지 업로드 프로세스의 각 단계
enum ImageUploadStep {
  thumbnail,  // 썸네일 생성 및 캐시 & 로컬 레포에 정보 저장
  upload,     // image upload service & callback
  tagging,    // image automatic tag list get
}

/// 단일 이미지의 업로드 진행 상황
class ImageUploadProgress {
  final String photoId;
  final String fileName;
  final Map<ImageUploadStep, bool> stepCompleted;
  final ImageUploadStep? failedStep;
  final String? errorMessage;

  const ImageUploadProgress({
    required this.photoId,
    required this.fileName,
    required this.stepCompleted,
    this.failedStep,
    this.errorMessage,
  });

  /// 전체 진행률 (0.0 ~ 1.0)
  double get progress {
    final completedCount = stepCompleted.values.where((v) => v).length;
    return completedCount / ImageUploadStep.values.length;
  }

  /// 모든 단계 완료 여부
  bool get isCompleted => stepCompleted.values.every((v) => v) && failedStep == null;

  /// 실패 여부
  bool get isFailed => failedStep != null;

  /// 현재 진행 중인 단계
  ImageUploadStep? get currentStep {
    if (failedStep != null) return failedStep;
    for (final step in ImageUploadStep.values) {
      if (!stepCompleted[step]!) {
        return step;
      }
    }
    return null;
  }

  /// 단계 완료 표시
  ImageUploadProgress completeStep(ImageUploadStep step) {
    final newSteps = Map<ImageUploadStep, bool>.from(stepCompleted);
    newSteps[step] = true;
    return ImageUploadProgress(
      photoId: photoId,
      fileName: fileName,
      stepCompleted: newSteps,
      failedStep: null,
      errorMessage: null,
    );
  }

  /// 단계 실패 표시
  ImageUploadProgress failStep(ImageUploadStep step, String error) {
    return ImageUploadProgress(
      photoId: photoId,
      fileName: fileName,
      stepCompleted: stepCompleted,
      failedStep: step,
      errorMessage: error,
    );
  }

  /// 재시도를 위해 실패 상태 초기화
  ImageUploadProgress resetFailure() {
    return ImageUploadProgress(
      photoId: photoId,
      fileName: fileName,
      stepCompleted: stepCompleted,
      failedStep: null,
      errorMessage: null,
    );
  }

  factory ImageUploadProgress.initial({
    required String photoId,
    required String fileName,
  }) {
    return ImageUploadProgress(
      photoId: photoId,
      fileName: fileName,
      stepCompleted: {
        for (var step in ImageUploadStep.values) step: false,
      },
    );
  }

  ImageUploadProgress copyWith({
    String? photoId,
    String? fileName,
    Map<ImageUploadStep, bool>? stepCompleted,
    ImageUploadStep? failedStep,
    String? errorMessage,
  }) {
    return ImageUploadProgress(
      photoId: photoId ?? this.photoId,
      fileName: fileName ?? this.fileName,
      stepCompleted: stepCompleted ?? this.stepCompleted,
      failedStep: failedStep,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() => 'ImageUploadProgress(photoId: $photoId, fileName: $fileName, progress: ${(progress * 100).toStringAsFixed(0)}%, failed: $isFailed)';
}