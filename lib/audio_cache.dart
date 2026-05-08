import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class AudioCacheManager {
  static final AudioCacheManager _instance = AudioCacheManager._internal();
  factory AudioCacheManager() => _instance;
  AudioCacheManager._internal();

  final Map<String, String> _cachedPaths = {};
  final Map<String, Duration> _durations = {};
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> preloadAll(List<String> assetPaths) async {
    // ב-Web לא צריך preload — just_audio מנגן assets ישירות
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/meme_sounds');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    await Future.wait(
      assetPaths.map((assetPath) async {
        try {
          final fileName = assetPath.split('/').last;
          final destPath = '${cacheDir.path}/$fileName';
          final destFile = File(destPath);

          if (!await destFile.exists()) {
            final byteData = await rootBundle.load(assetPath);
            await destFile.writeAsBytes(byteData.buffer.asUint8List());
          }
          _cachedPaths[assetPath] = destPath;

          // קבל את אורך הסאונד
          if (!_durations.containsKey(assetPath)) {
            final probe = AudioPlayer();
            await probe.setFilePath(destPath);
            final dur = probe.duration;
            if (dur != null) _durations[assetPath] = dur;
            await probe.dispose();
          }
        } catch (_) {}
      }),
    );

    _initialized = true;
  }

  String? getLocalPath(String assetPath) => _cachedPaths[assetPath];

  /// אורך הסאונד — null אם לא ידוע
  Duration? getDuration(String assetPath) => _durations[assetPath];
}
