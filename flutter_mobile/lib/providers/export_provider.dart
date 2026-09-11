import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/ffmpeg_export_service.dart';
import '../data/models/export_job.dart';
import '../data/services/export_service.dart';

final exportServiceProvider = Provider<ExportService>((ref) {
  return FfmpegExportService();
});

class ActiveExportJobNotifier extends StateNotifier<ExportJob?> {
  ActiveExportJobNotifier() : super(null);

  void setJob(ExportJob job) {
    state = job;
  }
  
  void startJob(ExportJob job, Stream<ExportJob> progressStream, {void Function()? onComplete}) {
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

final activeExportJobProvider = StateNotifierProvider<ActiveExportJobNotifier, ExportJob?>((ref) {
  return ActiveExportJobNotifier();
});
