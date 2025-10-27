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