/// Makes imported file names safe for `VideoPlayerController.file` URIs.
///
/// `?` and `#` in a path are treated as URI query/fragment and break ExoPlayer.
String sanitizeImportedFileName(String fileName) {
  return fileName.replaceAll(RegExp(r'[?#]'), '_');
}
