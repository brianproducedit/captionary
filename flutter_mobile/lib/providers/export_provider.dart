import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../core/subtitle_file_store.dart';
import '../data/models/export_job.dart';
import '../data/services/export_service.dart';
import '../data/services/ffmpeg_export_service.dart';

final exportServiceProvider = Provider<ExportService>((ref) {
  return FfmpegExportService();
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

  void setJob(ExportJob job) {
    state = job;
  }

  void startJob(
    ExportJob job,
    Stream<ExportJob> progressStream, {
    void Function()? onComplete,
  }) {
    state = job;
    progressStream.listen((updatedJob) {
      state = updatedJob;
      if (updatedJob.state == ExportState.complete) {
        onComplete?.call();
      }
    });
  }

  void clearJob() {
    state = null;
  }
}

final activeExportJobProvider =
    StateNotifierProvider<ActiveExportJobNotifier, ExportJob?>((ref) {
      return ActiveExportJobNotifier();
    });
