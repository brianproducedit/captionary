import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'glass_card.dart';

class StorageUsageBar extends StatelessWidget {
  final int mediaCacheBytes;
  final int modelCacheBytes;
  final int totalSpaceBytes;

  const StorageUsageBar({
    super.key,
    required this.mediaCacheBytes,
    required this.modelCacheBytes,
    required this.totalSpaceBytes,
  });

  @override
  Widget build(BuildContext context) {
    final mediaPct = totalSpaceBytes == 0 ? 0.0 : mediaCacheBytes / totalSpaceBytes;
    final modelPct = totalSpaceBytes == 0 ? 0.0 : modelCacheBytes / totalSpaceBytes;
    final freePct = 1.0 - mediaPct - modelPct;

    return GlassCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Storage Breakdown', style: Theme.of(context).textTheme.titleSmall),
              Text(
                '${(totalSpaceBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB Total',
                style: AppTypography.captionCode.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: (mediaPct * 1000).toInt(),
                    child: Container(color: AppColors.primary),
                  ),
                  Expanded(
                    flex: (modelPct * 1000).toInt(),
                    child: Container(color: AppColors.secondary),
                  ),
                  Expanded(
                    flex: (freePct * 1000).toInt(),
                    child: Container(color: AppColors.surfaceContainerHigh),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLegendItem('Media Cache', AppColors.primary, mediaCacheBytes),
              const SizedBox(width: 16),
              _buildLegendItem('Models', AppColors.secondary, modelCacheBytes),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int bytes) {
    final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($mb MB)',
          style: AppTypography.captionCode.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}
