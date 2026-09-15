/// Exception thrown when downloaded model file's SHA256 does not match manifest.
class ChecksumMismatchException implements Exception {
  final String modelId;
  final String expectedSha256;
  final String actualSha256;

  ChecksumMismatchException({
    required this.modelId,
    required this.expectedSha256,
    required this.actualSha256,
  });

  @override
  String toString() =>
      'ChecksumMismatchException for model "$modelId": expected $expectedSha256, got $actualSha256';
}

/// Exception thrown on path traversal or insecure URL/file resolution.
class SecurityException implements Exception {
  final String message;
  final String? path;

  SecurityException(this.message, [this.path]);

  @override
  String toString() =>
      'SecurityException: $message${path != null ? ' (path: $path)' : ''}';
}

/// Exception thrown when the catalog cannot be retrieved and no cache is available.
class CatalogUnavailableException implements Exception {
  final String message;
  final dynamic cause;

  CatalogUnavailableException(this.message, [this.cause]);

  @override
  String toString() =>
      'CatalogUnavailableException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Exception thrown when server returns an unexpected status during resumable download.
class DownloadResumeException implements Exception {
  final String message;
  final int? statusCode;

  DownloadResumeException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'DownloadResumeException: $message${statusCode != null ? ' (status: $statusCode)' : ''}';
}
