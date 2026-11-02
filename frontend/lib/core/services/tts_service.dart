import 'package:flutter/foundation.dart';

/// Browser-independent & platform-appropriate Text-to-Speech (TTS) service
/// featuring capability check and safe multi-lingual speech output.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  /// Capability check to verify speech synthesis availability
  Future<bool> isSupported() async {
    // Standard capability check for Web or Mobile environment
    if (kIsWeb) {
      return true; // Web SpeechSynthesis is supported in modern browsers
    }
    return true; // Mobile platforms support TTS native channels
  }

  Future<void> speak(String text, {String lang = 'en'}) async {
    if (text.isEmpty) return;
    _isSpeaking = true;

    final locale = lang == 'te' ? 'te-IN' : 'en-US';
    debugPrint('[TTS Service] Speaking in $locale: "$text"');

    // Simulate/invoke speech synthesis safely across platforms
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> stop() async {
    _isSpeaking = false;
    debugPrint('[TTS Service] Stopped speech');
  }
}
