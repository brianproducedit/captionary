import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:captionary/core/user_preferences.dart';
import 'package:captionary/providers/preferences_provider.dart';

void main() {
  test('preferences persist autoplay, quality, and ram tier', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifier = PreferencesNotifier(prefs);

    await notifier.setAutoPlay(true);
    await notifier.setExportQuality('720p');
    await notifier.setRamTier('High (6GB+)');
    await notifier.setPlaybackSpeed(1.5);
    await notifier.setVolume(0.4);
    await notifier.setExportFormat('vtt');

    final reloaded = PreferencesNotifier(prefs);
    expect(reloaded.state.autoPlay, isTrue);
    expect(reloaded.state.exportQuality, '720p');
    expect(reloaded.state.ramTier, 'High (6GB+)');
    expect(reloaded.state.playbackSpeed, 1.5);
    expect(reloaded.state.volume, 0.4);
    expect(reloaded.state.exportFormat, 'vtt');

    await reloaded.resetToDefaults();
    expect(reloaded.state.autoPlay, UserPreferences.defaults.autoPlay);
    expect(reloaded.state.exportQuality, '1080p');
    expect(reloaded.state.ramTier, 'Auto');
  });
}
