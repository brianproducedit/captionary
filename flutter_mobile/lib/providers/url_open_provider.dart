import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

typedef UrlOpenHandler = Future<bool> Function(Uri uri);

final urlOpenHandlerProvider = Provider<UrlOpenHandler>((ref) {
  return (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
});
