import 'package:flutter/material.dart';
import '../../data/models/photo_models.dart';

/// 확장 가능한 업로드 진행 위젯
class ExpandableUploadProgress extends StatefulWidget {
  final double overallProgress;
  final List<ImageUploadProgress> activeUploads;
  final List<ImageUploadProgress> completedUploads;
  final Function(String photoId)? onRetry;

  const ExpandableUploadProgress({
    super.key,
    required this.overallProgress,
    required this.activeUploads,
    required this.completedUploads,
    this.onRetry,
  });

  @override
  State<ExpandableUploadProgress> createState() => _ExpandableUploadProgressState();
}

class _ExpandableUploadProgressState extends State<ExpandableUploadProgress>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _sizeAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // 크기 애니메이션 (easeOutCubic 곡선 사용)
    _sizeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // 페이드 애니메이션
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // 애니메이션에 따른 크기 보간
        final width = _isExpanded
            ? 80 + (240 * _sizeAnimation.value)  // 80 -> 320
            : 80 + (240 * _sizeAnimation.value);
        final height = _isExpanded
            ? 80 + (320 * _sizeAnimation.value)  // 80 -> 400
            : 80 + (320 * _sizeAnimation.value);
        final borderRadius = _isExpanded
            ? 40 - (24 * _sizeAnimation.value)   // 40 -> 16
            : 40 - (24 * _sizeAnimation.value);

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: _sizeAnimation.value < 0.5
                ? _buildCollapsedView()
                : Stack(
                    children: [
                      Opacity(
                        opacity: _fadeAnimation.value,
                        child: _buildExpandedView(),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  /// 축소된 원형 진행 바
  Widget _buildCollapsedView() {
    final totalImages = widget.activeUploads.length + widget.completedUploads.length;
    final completedCount = widget.completedUploads.length;

    return InkWell(
      onTap: _toggleExpanded,
      borderRadius: BorderRadius.circular(40),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 원형 진행 바
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              value: widget.overallProgress,
              strokeWidth: 4,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
          // 진행 텍스트
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$completedCount',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '/ $totalImages',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 확장된 리스트 뷰
  Widget _buildExpandedView() {
    return Column(
      children: [
        // 헤더
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '업로드 진행',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: _toggleExpanded,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        // 진행 중인 이미지 리스트
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // 진행 중인 항목
              ...widget.activeUploads.map((progress) => _buildProgressItem(
                    progress,
                    isActive: true,
                  )),
              // 완료된 항목
              if (widget.activeUploads.isNotEmpty && widget.completedUploads.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(color: Colors.grey[300]),
                ),
              ...widget.completedUploads.map((progress) => _buildProgressItem(
                    progress,
                    isActive: false,
                  )),
            ],
          ),
        ),
        // 전체 진행 바 (하단)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '전체 진행',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '${(widget.overallProgress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: widget.overallProgress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 개별 이미지 진행 항목
  Widget _buildProgressItem(ImageUploadProgress progress, {required bool isActive}) {
    final isFailed = progress.isFailed;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFailed
            ? Colors.red[50]
            : (isActive ? Colors.blue[50] : Colors.grey[100]),
        border: isFailed
            ? Border.all(color: Colors.red[300]!, width: 1)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 파일명과 상태
          Row(
            children: [
              Expanded(
                child: Text(
                  progress.fileName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isFailed
                        ? Colors.red[900]
                        : (isActive ? Colors.black87 : Colors.grey[600]),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (progress.isCompleted)
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.green[600],
                )
              else if (isFailed)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error,
                      size: 16,
                      color: Colors.red[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '실패',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                )
              else
                Text(
                  '${(progress.progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
            ],
          ),

          // 에러 메시지 (실패한 경우)
          if (isFailed && progress.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              progress.errorMessage!,
              style: TextStyle(
                fontSize: 11,
                color: Colors.red[800],
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 8),

          // 단계별 진행 표시
          Row(
            children: [
              Expanded(
                child: Row(
                  children: ImageUploadStep.values.map((step) {
                    final isCompleted = progress.stepCompleted[step] ?? false;
                    final isCurrentStep = progress.currentStep == step;
                    final isFailedStep = progress.failedStep == step;

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          children: [
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: isFailedStep
                                    ? Colors.red[600]
                                    : isCompleted
                                        ? Theme.of(context).primaryColor
                                        : isCurrentStep
                                            ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
                                            : Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getStepLabel(step),
                              style: TextStyle(
                                fontSize: 9,
                                color: isFailedStep
                                    ? Colors.red[700]
                                    : (isCompleted || isCurrentStep
                                        ? Colors.grey[700]
                                        : Colors.grey[400]),
                                fontWeight: isFailedStep ? FontWeight.bold : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // 재시도 버튼 (실패한 경우)
              if (isFailed && widget.onRetry != null) ...[
                const SizedBox(width: 8),
                SizedBox(
                  height: 28,
                  child: ElevatedButton.icon(
                    onPressed: () => widget.onRetry!(progress.photoId),
                    icon: const Icon(Icons.refresh, size: 14),
                    label: const Text('재시도', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 단계별 라벨
  String _getStepLabel(ImageUploadStep step) {
    switch (step) {
      case ImageUploadStep.thumbnail:
        return '썸네일';
      case ImageUploadStep.upload:
        return '업로드';
      case ImageUploadStep.tagging:
        return '태깅';
    }
  }
}