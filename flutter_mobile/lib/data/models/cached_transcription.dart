import 'subtitle_segment.dart';

/// Represents cached transcription data for a previously processed video file.
class CachedTranscription {
  final String videoPath;
  final String mediaId;
  final String? fileHash;
  final int? fileSizeBytes;
  final DateTime? lastModified;
  final List<SubtitleSegment> segments;
  final String? languageCode;
  final String? detectedLanguage;
  final String? modelQuality;
  final bool translateToEnglish;
  final DateTime createdAt;
  final DateTime updatedAt;

  CachedTranscription({
    required this.videoPath,
    required this.mediaId,
    this.fileHash,
    this.fileSizeBytes,
    this.lastModified,
    required this.segments,
    this.languageCode,
    this.detectedLanguage,
    this.modelQuality,
    this.translateToEnglish = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'videoPath': videoPath,
      'mediaId': mediaId,
      'fileHash': fileHash,
      'fileSizeBytes': fileSizeBytes,
      'lastModified': lastModified?.toIso8601String(),
      'segments': segments.map((s) => s.toJson()).toList(),
      'languageCode': languageCode,
      'detectedLanguage': detectedLanguage,
      'modelQuality': modelQuality,
      'translateToEnglish': translateToEnglish,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CachedTranscription.fromJson(Map<String, dynamic> json) {
    final rawSegments = json['segments'] as List<dynamic>? ?? [];
    final segments = rawSegments
        .map((s) => SubtitleSegment.fromJson(s as Map<String, dynamic>))
        .toList();

    return CachedTranscription(
      videoPath: json['videoPath'] as String? ?? '',
      mediaId: json['mediaId'] as String? ?? '',
      fileHash: json['fileHash'] as String?,
      fileSizeBytes: json['fileSizeBytes'] as int?,
      lastModified: json['lastModified'] != null
          ? DateTime.tryParse(json['lastModified'] as String)
          : null,
      segments: segments,
      languageCode: json['languageCode'] as String?,
      detectedLanguage: json['detectedLanguage'] as String?,
      modelQuality: json['modelQuality'] as String?,
      translateToEnglish: json['translateToEnglish'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  CachedTranscription copyWith({
    String? videoPath,
    String? mediaId,
    String? fileHash,
    int? fileSizeBytes,
    DateTime? lastModified,
    List<SubtitleSegment>? segments,
    String? languageCode,
    String? detectedLanguage,
    String? modelQuality,
    bool? translateToEnglish,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CachedTranscription(
      videoPath: videoPath ?? this.videoPath,
      mediaId: mediaId ?? this.mediaId,
      fileHash: fileHash ?? this.fileHash,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      lastModified: lastModified ?? this.lastModified,
      segments: segments ?? this.segments,
      languageCode: languageCode ?? this.languageCode,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      modelQuality: modelQuality ?? this.modelQuality,
      translateToEnglish: translateToEnglish ?? this.translateToEnglish,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
