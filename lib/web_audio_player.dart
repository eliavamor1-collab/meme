import 'dart:js_interop';
import 'package:flutter/foundation.dart' show kIsWeb;

@JS('playOpusAsset')
external void _jsPlayOpusAsset(String url, JSFunction? onEnded);

@JS('stopAudio')
external void _jsStopAudio();

/// מנגן audio ב-Web דרך Web Audio API (תומך OPUS)
class WebAudioPlayer {
  static final WebAudioPlayer _instance = WebAudioPlayer._internal();
  factory WebAudioPlayer() => _instance;
  WebAudioPlayer._internal();

  void play(String assetPath, {void Function()? onEnded}) {
    if (!kIsWeb) return;

    // בנה URL נכון ל-Flutter Web asset
    final encodedPath = assetPath.split('/').map(Uri.encodeComponent).join('/');
    final url = 'assets/$encodedPath';

    final callback = onEnded != null ? (() => onEnded()).toJS : null;
    _jsPlayOpusAsset(url, callback);
  }

  void stop() {
    if (!kIsWeb) return;
    _jsStopAudio();
  }
}
