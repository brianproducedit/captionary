import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:material_symbols_icons/symbols.dart';

import '../core/caption_export.dart';
import '../core/subtitle_file_store.dart';
import '../data/models/subtitle_segment.dart';
import '../providers/caption_style_provider.dart';
import '../providers/export_provider.dart';
import '../providers/subtitle_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_toast.dart';
import '../widgets/ghost_pill_button.dart';
import '../widgets/gradient_pill_button.dart';

class CaptionExportSheet extends ConsumerStatefulWidget {
  final String? initialFileName;
  const CaptionExportSheet({super.key, this.initialFileName});

  @override
  ConsumerState<CaptionExportSheet> createState() => _CaptionExportSheetState();
}

class _CaptionExportSheetState extends ConsumerState<CaptionExportSheet> {
  CaptionExportFormat _format = CaptionExportFormat.srt;
  bool _busy = false;
  late final TextEditingController _fileNameController;

  @override
  void initState() {
    super.initState();
    _fileNameController = TextEditingController(
      text: widget.initialFileName?.trim().isNotEmpty == true
          ? widget.initialFileName!.trim()
          : 'captions',
    );
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  String _sanitizeFileName(String name) {
    final sanitized = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return sanitized.isEmpty ? 'captions' : sanitized;
  }

  Future<void> _export(List<SubtitleSegment> segments) async {
    final reason = CaptionExport.blockReason(segments);
    if (reason != null || !_format.isAvailable) return;

    setState(() => _busy = true);
    try {
      final service = ref.read(exportServiceProvider);
      final style = ref.read(captionStyleProvider);
      final String content;
      switch (_format) {
        case CaptionExportFormat.vtt:
          content = await service.exportVTT(segments);
          break;
        case CaptionExportFormat.ass:
          content = await service.exportASS(segments, style: style);
          break;
        case CaptionExportFormat.srt:
          content = await service.exportSRT(segments);
          break;
      }
      final safeName = _sanitizeFileName(_fileNameController.text);
      final fileName = '$safeName.${_format.fileExtension}';
      final file = await ref
          .read(subtitleFileStoreProvider)
          .write(fileName: fileName, content: content);
      await ref.read(captionShareHandlerProvider)(
        CaptionShareRequest(
          path: file.path,
          mimeType: _format.mimeType,
          fileName: fileName,
        ),
      );
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      AppToast.show(
        context,
        message: 'Saved $fileName',
        variant: AppToastVariant.success,
      );
    } catch (error) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Could not export captions: $error',
        variant: AppToastVariant.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final segments = ref.watch(subtitleProvider);
    final reason = CaptionExport.blockReason(segments);
    final canExport = reason == null && _format.isAvailable && !_busy;

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Export captions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Writes an SRT, VTT, or styled ASS file and opens the system share sheet.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 4.0,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Symbols.drive_file_rename_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _fileNameController,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.allWhite,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter caption file name',
                          hintStyle: TextStyle(
                            color: AppColors.onSurfaceVariant,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    Text(
                      '.${_format.fileExtension}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  for (final format in CaptionExportFormat.values)
                    ChoiceChip(
                      key: ValueKey('format-${format.name}'),
                      label: Text(format.label),
                      selected: _format == format,
                      onSelected: format.isAvailable
                          ? (selected) {
                              if (selected) setState(() => _format = format);
                            }
                          : null,
                    ),
                ],
              ),
              if (!_format.isAvailable) ...[
                const SizedBox(height: 8),
                const Text('Selected format is not available.'),
              ],
              if (reason != null) ...[
                const SizedBox(height: 12),
                Text(
                  reason,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.error),
                ),
              ],
              const SizedBox(height: 24),
              GradientPillButton(
                label: _busy ? 'Exporting…' : 'Export ${_format.label}',
                onTap: canExport ? () => _export(segments) : null,
                isFullWidth: true,
              ),
              if (!canExport && reason != null) ...[
                const SizedBox(height: 8),
                GhostPillButton(
                  label: 'Fix captions to enable export',
                  onTap: null,
                  isFullWidth: true,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
