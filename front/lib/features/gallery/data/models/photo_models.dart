/// Represents a tag attached to a photo
class PhotoTag {
  final String id;
  final String name;
  final TagType type;

  const PhotoTag({required this.id, required this.name, required this.type});

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
    return {'id': id, 'name': name, 'type': type.name};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoTag && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PhotoTag(id: $id, name: $name, type: $type)';
}

enum TagType {
  user, // 사용자가 추가한 태그
  system, // AI/시스템이 자동으로 생성한 태그
}

class PhotoMetadata {
  final String? location;
  final String? camera;
  final String? resolution;
  final List<PhotoTag> userTags;
  final List<PhotoTag> systemTags;
  final Map<String, dynamic>? additionalInfo;
  final int? width;
  final int? height;
  final int? fileSize;
  final DateTime? dateTaken;
  final String? mimeType;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? exifData;

  const PhotoMetadata({
    this.location,
    this.camera,
    this.resolution,
    this.userTags = const [],
    this.systemTags = const [],
    this.additionalInfo,
    this.width,
    this.height,
    this.fileSize,
    this.dateTaken,
    this.mimeType,
    this.latitude,
    this.longitude,
    this.exifData,
  });

  factory PhotoMetadata.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const PhotoMetadata();
    }

    final userTagsList =
        (map['userTags'] as List<dynamic>?)
            ?.map((tag) => PhotoTag.fromMap(tag as Map<String, dynamic>))
            .toList() ??
        [];

    final systemTagsList =
        (map['systemTags'] as List<dynamic>?)
            ?.map((tag) => PhotoTag.fromMap(tag as Map<String, dynamic>))
            .toList() ??
        [];

    return PhotoMetadata(
      location: map['location'],
      camera: map['camera'],
      resolution: map['resolution'],
      userTags: userTagsList,
      systemTags: systemTagsList,
      additionalInfo: map['additionalInfo'],
      width: map['width'] ?? map['image_width'],
      height: map['height'] ?? map['image_height'],
      fileSize: map['fileSize'] ?? map['file_size'],
      dateTaken: map['dateTaken'] != null
          ? DateTime.tryParse(map['dateTaken'])
          : map['date_taken'] != null
          ? DateTime.tryParse(map['date_taken'])
          : null,
      mimeType: map['mimeType'] ?? map['mime_type'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      exifData: map['exifData'] ?? map['exif_data'],
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
      'width': width,
      'height': height,
      'fileSize': fileSize,
      'dateTaken': dateTaken?.toIso8601String(),
      'mimeType': mimeType,
      'latitude': latitude,
      'longitude': longitude,
      'exifData': exifData,
    };
  }

  PhotoMetadata copyWith({
    String? location,
    String? camera,
    String? resolution,
    List<PhotoTag>? userTags,
    List<PhotoTag>? systemTags,
    Map<String, dynamic>? additionalInfo,
    int? width,
    int? height,
    int? fileSize,
    DateTime? dateTaken,
    String? mimeType,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? exifData,
  }) {
    return PhotoMetadata(
      location: location ?? this.location,
      camera: camera ?? this.camera,
      resolution: resolution ?? this.resolution,
      userTags: userTags ?? this.userTags,
      systemTags: systemTags ?? this.systemTags,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSize: fileSize ?? this.fileSize,
      dateTaken: dateTaken ?? this.dateTaken,
      mimeType: mimeType ?? this.mimeType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      exifData: exifData ?? this.exifData,
    );
  }

  Map<String, dynamic> toApiPayload() => {
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    if (fileSize != null) 'file_size': fileSize,
    if (dateTaken != null) 'date_taken': dateTaken!.toIso8601String(),
    if (mimeType != null) 'mime_type': mimeType,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (exifData != null) 'exif_data': exifData,
  };

  /// Gets all tags (user + system)
  List<PhotoTag> get allTags => [...userTags, ...systemTags];

  @override
  String toString() =>
      'PhotoMetadata(width: $width, height: $height, userTags: ${userTags.length}, systemTags: ${systemTags.length})';
}

/// 업로드 상태
enum UploadStatus {
  pending, // 업로드 대기 중
  uploading, // 업로드 중
  completed, // 업로드 완료
  failed, // 업로드 실패
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

  const PhotoSection({required this.date, required this.imageCount});

  /// Creates a copy of this PhotoSection with the given fields replaced
  PhotoSection copyWith({String? date, int? imageCount}) {
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
  final String clientId; // 클라이언트 ID (요청 시 보낸 ID)
  final int imageId; // 실제 서버 이미지 ID
  final String presignedUrl;

  const PresignedUrlData({
    required this.clientId,
    required this.imageId,
    required this.presignedUrl,
  });

  factory PresignedUrlData.fromMap(Map<String, dynamic> map) {
    return PresignedUrlData(
      clientId: map['client_id'] ?? '',
      imageId: map['image_id'] ?? 0,
      presignedUrl: map['presigned_url'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'client_id': clientId,
      'image_id': imageId,
      'presigned_url': presignedUrl,
    };
  }

  @override
  String toString() =>
      'PresignedUrlData(clientId: $clientId, imageId: $imageId, presignedUrl: $presignedUrl)';
}

/// Represents the response from presigned URL request
class PresignedUrlResponse {
  final List<PresignedUrlData> presignedUrls;
  final List<DuplicateImageInfo> duplicates; // 중복된 이미지 정보

  const PresignedUrlResponse({
    required this.presignedUrls,
    this.duplicates = const [],
  });

  factory PresignedUrlResponse.fromMap(Map<String, dynamic> map) {
    final urls =
        (map['uploads'] as List<dynamic>?)
            ?.map(
              (item) => PresignedUrlData.fromMap(item as Map<String, dynamic>),
            )
            .toList() ??
        [];

    final duplicatesList =
        (map['duplicates'] as List<dynamic>?)
            ?.map(
              (item) =>
                  DuplicateImageInfo.fromMap(item as Map<String, dynamic>),
            )
            .toList() ??
        [];

    return PresignedUrlResponse(
      presignedUrls: urls,
      duplicates: duplicatesList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uploads': presignedUrls.map((url) => url.toMap()).toList(),
      'duplicates': duplicates.map((dup) => dup.toMap()).toList(),
    };
  }

  @override
  String toString() =>
      'PresignedUrlResponse(presignedUrls: ${presignedUrls.length}, duplicates: ${duplicates.length})';
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
    return {'loc': loc, 'msg': msg, 'type': type};
  }

  @override
  String toString() =>
      'ValidationErrorDetail(loc: $loc, msg: $msg, type: $type)';
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
    return {'image_id': imageId, 'status': status, 'hash': hash};
  }

  @override
  String toString() =>
      'UploadCompleteResponse(imageId: $imageId, status: $status, hash: $hash)';
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

/// 이미지 메타데이터 (OpenAPI 스펙)
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

  factory ImageMetadata.fromMap(Map<String, dynamic> map) {
    return ImageMetadata(
      width: map['width'] as int? ?? 0,
      height: map['height'] as int? ?? 0,
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
}

/// 백엔드 API 이미지 응답 모델 (OpenAPI 스펙)
class ImageResponse {
  final int id;
  final String? url;  // nullable according to OpenAPI spec
  final DateTime uploadedAt;
  final AIProcessingStatus status;

  // Extended fields (not in basic response)
  final int? userId;
  final String? s3Key;
  final String? hash;
  final int? fileSize;
  final DateTime? deletedAt;
  final String? aiDescription;
  final List<String> aiTags;
  final ImageMetadata? metadata;

  const ImageResponse({
    required this.id,
    this.url,
    required this.uploadedAt,
    required this.status,
    this.userId,
    this.s3Key,
    this.hash,
    this.fileSize,
    this.deletedAt,
    this.aiDescription,
    this.aiTags = const [],
    this.metadata,
  });

  factory ImageResponse.fromMap(Map<String, dynamic> map) {
    return ImageResponse(
      id: map['id'] as int? ?? 0,
      url: map['url'] as String?,  // nullable
      uploadedAt: map['uploaded_at'] != null
          ? DateTime.parse(map['uploaded_at'] as String)
          : DateTime.now(),
      status: AIProcessingStatus.fromString(
        (map['ai_processing_status'] as String?) ??
        (map['status'] as String?) ??
        'PENDING'
      ),
      userId: map['user_id'] as int?,
      s3Key: map['s3_key'] as String?,
      hash: map['hash'] as String?,
      fileSize: map['file_size'] as int?,
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
      aiDescription: map['ai_description'] as String?,
      aiTags: (map['ai_tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      metadata: map['metadata'] != null
          ? ImageMetadata.fromMap(map['metadata'] as Map<String, dynamic>)
          : null,
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

  Photo toPhoto({String? viewUrl, String? localThumbnailPath}) {
    return Photo(
      id: id.toString(),
      url: localThumbnailPath ?? viewUrl ?? '',
      remoteUrl: viewUrl,
      fileName: s3Key?.split('/').last ?? 'unknown',
      createdAt: uploadedAt,
      fileSize: fileSize,
      metadata: PhotoMetadata(
        systemTags: aiTags.map((tag) => PhotoTag(
          id: tag,
          name: tag,
          type: TagType.system,
        )).toList(),
        additionalInfo: metadata?.toMap(),
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
  String toString() => 'ImageResponse(id: $id, url: $url, status: $status)';
}

/// 이미지 view URL 응답 (OpenAPI 스펙)
class ImageViewableResponse {
  final int imageId;
  final String url;

  const ImageViewableResponse({
    required this.imageId,
    required this.url,
  });

  factory ImageViewableResponse.fromMap(Map<String, dynamic> map) {
    return ImageViewableResponse(
      imageId: map['image_id'] as int? ?? 0,
      url: (map['url'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'image_id': imageId,
      'url': url,
    };
  }

  @override
  String toString() => 'ImageViewableResponse(imageId: $imageId, url: $url)';
}

/// 이미지 업로드 프로세스의 각 단계
enum ImageUploadStep {
  thumbnail,  // 썸네일 생성 및 캐시 & 로컬 레포에 정보 저장
  upload,     // image upload service & backend notification
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
  bool get isCompleted =>
      stepCompleted.values.every((v) => v) && failedStep == null;

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
      stepCompleted: {for (var step in ImageUploadStep.values) step: false},
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
  String toString() =>
      'ImageUploadProgress(photoId: $photoId, fileName: $fileName, progress: ${(progress * 100).toStringAsFixed(0)}%, failed: $isFailed)';
}

/// 중복 검사 요청 데이터
class DuplicateCheckItem {
  final int tempId; // 임시 ID (0부터 시작)
  final String hash; // 이미지 파일 해시값

  const DuplicateCheckItem({required this.tempId, required this.hash});

  Map<String, dynamic> toMap() {
    return {'client_id': tempId.toString(), 'hash': hash};
  }

  @override
  String toString() => 'DuplicateCheckItem(tempId: $tempId, hash: $hash)';
}

/// 중복 검사 요청 모델
class DuplicateCheckRequest {
  final List<DuplicateCheckItem> images;

  const DuplicateCheckRequest({required this.images});

  Map<String, dynamic> toMap() {
    return {'images': images.map((item) => item.toMap()).toList()};
  }

  @override
  String toString() => 'DuplicateCheckRequest(images: ${images.length})';
}

/// 중복 이미지 응답 데이터
class DuplicateImageInfo {
  final String clientId; // 클라이언트 ID
  final int existingImageId; // 기존 이미지의 실제 ID

  const DuplicateImageInfo({
    required this.clientId,
    required this.existingImageId,
  });

  factory DuplicateImageInfo.fromMap(Map<String, dynamic> map) {
    return DuplicateImageInfo(
      clientId: map['client_id'] ?? '',
      existingImageId: map['existing_image_id'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'client_id': clientId, 'existing_image_id': existingImageId};
  }

  // tempId를 int로 파싱하는 getter (내부 로직용)
  int get tempId => int.tryParse(clientId) ?? 0;

  @override
  String toString() =>
      'DuplicateImageInfo(clientId: $clientId, existingImageId: $existingImageId)';
}

/// 중복 검사 응답 모델
class DuplicateCheckResponse {
  final List<DuplicateImageInfo> duplicates;

  const DuplicateCheckResponse({required this.duplicates});

  factory DuplicateCheckResponse.fromMap(Map<String, dynamic> map) {
    final duplicatesList =
        (map['duplicates'] as List<dynamic>?)
            ?.map(
              (item) =>
                  DuplicateImageInfo.fromMap(item as Map<String, dynamic>),
            )
            .toList() ??
        [];

    return DuplicateCheckResponse(duplicates: duplicatesList);
  }

  Map<String, dynamic> toMap() {
    return {'duplicates': duplicates.map((item) => item.toMap()).toList()};
  }

  @override
  String toString() =>
      'DuplicateCheckResponse(duplicates: ${duplicates.length})';
}
