import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../providers/crop_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Interactive crop overlay with draggable corner handles, aspect ratio presets,
/// and a rule-of-thirds composition grid.
class CropOverlay extends ConsumerStatefulWidget {
  final double videoAspectRatio;

  const CropOverlay({super.key, this.videoAspectRatio = 16 / 9});

  @override
  ConsumerState<CropOverlay> createState() => _CropOverlayState();
}

class _CropOverlayState extends ConsumerState<CropOverlay> {
  static const double _handleSize = 24.0;
  static const double _handleHitArea = 40.0;
  String? _activeHandle; // 'tl', 'tr', 'bl', 'br', 'move'
  Offset? _dragStart;
  Rect? _rectAtDragStart;

  @override
  Widget build(BuildContext context) {
    final crop = ref.watch(cropProvider);
    if (!crop.isEnabled) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPresetChips(crop),
        const SizedBox(height: 8),
        Expanded(child: _buildCropCanvas(crop)),
      ],
    );
  }

  Widget _buildPresetChips(CropState crop) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: CropAspectRatio.values.map((ratio) {
          final isSelected = crop.ratio == ratio;
          final state = CropState(ratio: ratio);
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(
                state.label,
                style: AppTypography.labelMd.copyWith(
                  color: isSelected
                      ? AppColors.baseCanvas
                      : AppColors.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (_) {
                ref.read(cropProvider.notifier).setAspectRatio(ratio);
                _applyRatioRect(ratio);
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceContainerLow,
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surfaceContainerHigh,
              ),
              showCheckmark: false,
              avatar: isSelected
                  ? const Icon(
                      Symbols.check_circle,
                      size: 16,
                      color: AppColors.baseCanvas,
                    )
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  void _applyRatioRect(CropAspectRatio ratio) {
    if (ratio == CropAspectRatio.original) {
      ref.read(cropProvider.notifier).reset();
      return;
    }

    final targetRatio = CropState(ratio: ratio).targetRatio;
    if (targetRatio == null) return;

    // Compute centered crop rect that fits the target ratio inside the video
    final videoRatio = widget.videoAspectRatio;
    double width, height;
    if (targetRatio > videoRatio) {
      // Target is wider than video — full width, reduced height
      width = 1.0;
      height = (videoRatio / targetRatio).clamp(0.1, 1.0);
    } else {
      // Target is taller than video — full height, reduced width
      height = 1.0;
      width = (targetRatio / videoRatio).clamp(0.1, 1.0);
    }

    final left = (1.0 - width) / 2;
    final top = (1.0 - height) / 2;
    final rect = Rect.fromLTWH(left, top, width, height);
    ref.read(cropProvider.notifier).setCropRect(rect);
  }

  Widget _buildCropCanvas(CropState crop) {
    final rect = crop.cropRect ?? const Rect.fromLTWH(0.0, 0.0, 1.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasW = constraints.maxWidth;
        final canvasH = constraints.maxHeight;

        final pixelRect = Rect.fromLTWH(
          rect.left * canvasW,
          rect.top * canvasH,
          rect.width * canvasW,
          rect.height * canvasH,
        );

        return GestureDetector(
          onPanStart: (details) =>
              _onPanStart(details, pixelRect, canvasW, canvasH),
          onPanUpdate: (details) => _onPanUpdate(details, canvasW, canvasH),
          onPanEnd: (_) => _onPanEnd(),
          child: Stack(
            children: [
              // Dimmed areas outside crop
              _buildDimOverlay(pixelRect, canvasW, canvasH),
              // Crop border
              Positioned.fromRect(
                rect: pixelRect,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.allWhite, width: 2),
                  ),
                  child: _buildGrid(),
                ),
              ),
              // Corner handles
              _buildHandle(pixelRect.topLeft, 'tl'),
              _buildHandle(pixelRect.topRight, 'tr'),
              _buildHandle(pixelRect.bottomLeft, 'bl'),
              _buildHandle(pixelRect.bottomRight, 'br'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDimOverlay(Rect crop, double w, double h) {
    return CustomPaint(
      size: Size(w, h),
      painter: _DimPainter(cropRect: crop),
    );
  }

  /// 3×3 rule-of-thirds grid.
  Widget _buildGrid() {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GridPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildHandle(Offset position, String id) {
    return Positioned(
      left: position.dx - _handleSize / 2,
      top: position.dy - _handleSize / 2,
      width: _handleHitArea,
      height: _handleHitArea,
      child: Center(
        child: Container(
          width: _handleSize,
          height: _handleSize,
          decoration: BoxDecoration(
            color: AppColors.allWhite,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onPanStart(
    DragStartDetails details,
    Rect pixelRect,
    double canvasW,
    double canvasH,
  ) {
    final pos = details.localPosition;
    const threshold = _handleHitArea;

    if ((pos - pixelRect.topLeft).distance < threshold) {
      _activeHandle = 'tl';
    } else if ((pos - pixelRect.topRight).distance < threshold) {
      _activeHandle = 'tr';
    } else if ((pos - pixelRect.bottomLeft).distance < threshold) {
      _activeHandle = 'bl';
    } else if ((pos - pixelRect.bottomRight).distance < threshold) {
      _activeHandle = 'br';
    } else if (pixelRect.contains(pos)) {
      _activeHandle = 'move';
    } else {
      _activeHandle = null;
    }

    _dragStart = pos;
    _rectAtDragStart = Rect.fromLTWH(
      pixelRect.left / canvasW,
      pixelRect.top / canvasH,
      pixelRect.width / canvasW,
      pixelRect.height / canvasH,
    );
  }

  void _onPanUpdate(DragUpdateDetails details, double canvasW, double canvasH) {
    if (_activeHandle == null || _rectAtDragStart == null || _dragStart == null) {
      return;
    }

    final dx = (details.localPosition.dx - _dragStart!.dx) / canvasW;
    final dy = (details.localPosition.dy - _dragStart!.dy) / canvasH;
    final r = _rectAtDragStart!;

    Rect newRect;
    switch (_activeHandle) {
      case 'tl':
        newRect = Rect.fromLTRB(
          (r.left + dx).clamp(0.0, r.right - 0.1),
          (r.top + dy).clamp(0.0, r.bottom - 0.1),
          r.right,
          r.bottom,
        );
        break;
      case 'tr':
        newRect = Rect.fromLTRB(
          r.left,
          (r.top + dy).clamp(0.0, r.bottom - 0.1),
          (r.right + dx).clamp(r.left + 0.1, 1.0),
          r.bottom,
        );
        break;
      case 'bl':
        newRect = Rect.fromLTRB(
          (r.left + dx).clamp(0.0, r.right - 0.1),
          r.top,
          r.right,
          (r.bottom + dy).clamp(r.top + 0.1, 1.0),
        );
        break;
      case 'br':
        newRect = Rect.fromLTRB(
          r.left,
          r.top,
          (r.right + dx).clamp(r.left + 0.1, 1.0),
          (r.bottom + dy).clamp(r.top + 0.1, 1.0),
        );
        break;
      case 'move':
        final w = r.width;
        final h = r.height;
        var newLeft = (r.left + dx).clamp(0.0, 1.0 - w);
        var newTop = (r.top + dy).clamp(0.0, 1.0 - h);
        newRect = Rect.fromLTWH(newLeft, newTop, w, h);
        break;
      default:
        return;
    }

    ref.read(cropProvider.notifier).setCropRect(newRect);
  }

  void _onPanEnd() {
    _activeHandle = null;
    _dragStart = null;
    _rectAtDragStart = null;
  }
}

class _DimPainter extends CustomPainter {
  final Rect cropRect;
  _DimPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    // Top
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, cropRect.top), dimPaint);
    // Bottom
    canvas.drawRect(
      Rect.fromLTRB(0, cropRect.bottom, size.width, size.height),
      dimPaint,
    );
    // Left
    canvas.drawRect(
      Rect.fromLTRB(0, cropRect.top, cropRect.left, cropRect.bottom),
      dimPaint,
    );
    // Right
    canvas.drawRect(
      Rect.fromLTRB(cropRect.right, cropRect.top, size.width, cropRect.bottom),
      dimPaint,
    );
  }

  @override
  bool shouldRepaint(_DimPainter oldDelegate) =>
      oldDelegate.cropRect != cropRect;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 0.7;

    // Vertical lines at 1/3 and 2/3
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(2 * size.width / 3, 0),
      Offset(2 * size.width / 3, size.height),
      paint,
    );
    // Horizontal lines at 1/3 and 2/3
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, 2 * size.height / 3),
      Offset(size.width, 2 * size.height / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
