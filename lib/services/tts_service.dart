import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Service untuk Text-to-Speech (TTS) Pelafalan Bahasa Jepang (Choukai & Aksen)
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  final ValueNotifier<bool> isSpeaking = ValueNotifier<bool>(false);
  final ValueNotifier<String?> currentlySpeakingText = ValueNotifier<String?>(null);

  /// Inisialisasi engine TTS dengan bahasa Jepang (ja-JP)
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await _flutterTts.setLanguage('ja-JP');
      await _flutterTts.setSpeechRate(0.48); // Kecepatan ideal untuk belajar bahasa Jepang
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        isSpeaking.value = true;
      });

      _flutterTts.setCompletionHandler(() {
        isSpeaking.value = false;
        currentlySpeakingText.value = null;
      });

      _flutterTts.setCancelHandler(() {
        isSpeaking.value = false;
        currentlySpeakingText.value = null;
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        isSpeaking.value = false;
        currentlySpeakingText.value = null;
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  /// Membunyikan teks bahasa Jepang
  Future<void> speakJapanese(
    String text, {
    double? rate,
    double? pitch,
  }) async {
    if (text.trim().isEmpty) return;

    if (!_isInitialized) {
      await init();
    }

    try {
      await stop();

      if (rate != null) {
        await _flutterTts.setSpeechRate(rate);
      } else {
        await _flutterTts.setSpeechRate(0.48);
      }

      if (pitch != null) {
        await _flutterTts.setPitch(pitch);
      }

      await _flutterTts.setLanguage('ja-JP');
      currentlySpeakingText.value = text;
      isSpeaking.value = true;
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
      isSpeaking.value = false;
      currentlySpeakingText.value = null;
    }
  }

  /// Membunyikan teks bahasa Indonesia (misal arti/deskripsi)
  Future<void> speakIndonesian(String text) async {
    if (text.trim().isEmpty) return;
    if (!_isInitialized) await init();

    try {
      await stop();
      await _flutterTts.setLanguage('id-ID');
      await _flutterTts.setSpeechRate(0.5);
      currentlySpeakingText.value = text;
      isSpeaking.value = true;
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS Indonesian error: $e');
    }
  }

  /// Menghentikan audio pelafalan
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      isSpeaking.value = false;
      currentlySpeakingText.value = null;
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }
}
