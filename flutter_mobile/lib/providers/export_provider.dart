import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../core/subtitle_file_store.dart';
import '../data/mock/mock_export_service.dart';
import '../data/models/export_job.dart';
import '../data/services/export_service.dart';
import '../data/services/ffmpeg_export_service.dart';
import 'backend_mode_provider.dart';

final exportServiceProvider = Provider<ExportService>((ref) {
  final mode = ref.watch(backendModeProvider);
  switch (mode) {
    case BackendMode.mock:
      return MockExportService();
    case BackendMode.local:
    case BackendMode.real:
      return FfmpegExportService();
  }
});

final subtitleFileStoreProvider = Provider<SubtitleFileStore>((ref) {
  return SubtitleFileStore();
});

final captionShareHandlerProvider = Provider<CaptionShareHandler>((ref) {
  return (request) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            request.path,
            mimeType: request.mimeType,
            name: request.fileName,
          ),
        ],
      ),
    );
  };
});

class ActiveExportJobNotifier extends StateNotifier<ExportJob?> {
  ActiveExportJobNotifier() : super(null);

  StreamSubscription<ExportJob>? _subscription;
  Future<void> Function()? _onCancel;

  void setJob(ExportJob job) {
    state = job;
  }

  void startJob(
    ExportJob job,
    Stream<ExportJob> progressStream, {
    void Function()? onComplete,
    Future<void> Function()? onCancel,
  }) {
    _subscription?.cancel();
    _onCancel = onCancel;
    state = job;
    _subscription = progressStream.listen((updatedJob) {
      state = updatedJob;
      if (updatedJob.state == ExportState.complete) {
        onComplete?.call();
      }
    });
  }

  Future<void> cancelJob() async {
    try {
      await _onCancel?.call();
    } catch (_) {}
    _subscription?.cancel();
    _subscription = null;
    if (state != null) {
      state = state!.copyWith(state: ExportState.cancelled);
    }
  }

  void clearJob() {
    _subscription?.cancel();
    _subscription = null;
    _onCancel = null;
    state = null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _onCancel = null;
    super.dispose();
  }
}

final activeExportJobProvider =
    StateNotifierProvider<ActiveExportJobNotifier, ExportJob?>((ref) {
      final notifier = ActiveExportJobNotifier();
      ref.onDispose(() => notifier.dispose());
      return notifier;
    });
