import 'package:flutter_tts/flutter_tts.dart';

enum TtsLanguageSupport { available, unavailable, unknown }

/// Full-featured wrapper around flutter_tts: speech rate/pitch control
/// and runtime detection of Bangla voice availability. Bangla TTS
/// support varies significantly across Android OEMs/versions — some
/// devices have no bn-BD/bn-IN voice installed at all. Rather than
/// assuming support and failing silently, we check once and cache
/// the result so the UI can adapt (e.g. disable/hide the Bangla
/// speak button with an explanatory tooltip).
class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  TtsLanguageSupport _banglaSupport = TtsLanguageSupport.unknown;

  double _speechRate = 0.45;
  double _pitch = 1.0;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setPitch(_pitch);
    _isInitialized = true;
  }

  Future<TtsLanguageSupport> checkBanglaSupport() async {
    if (_banglaSupport != TtsLanguageSupport.unknown) return _banglaSupport;
    try {
      final languages = await _flutterTts.getLanguages;
      final available = (languages as List).cast<String>();
      final hasBangla = available.any((lang) => lang.toLowerCase().startsWith('bn'));
      _banglaSupport = hasBangla ? TtsLanguageSupport.available : TtsLanguageSupport.unavailable;
    } catch (e) {
      _banglaSupport = TtsLanguageSupport.unavailable;
    }
    return _banglaSupport;
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    await _flutterTts.setSpeechRate(rate);
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    await _flutterTts.setPitch(pitch);
  }

  double get speechRate => _speechRate;
  double get pitch => _pitch;

  Future<void> speak(String text, {String languageCode = 'en-US'}) async {
    await _ensureInitialized();
    await _flutterTts.setLanguage(languageCode);
    await _flutterTts.speak(text);
  }

  Future<void> speakEnglish(String text) => speak(text, languageCode: 'en-US');

  /// Attempts Bangla speech; caller should check checkBanglaSupport()
  /// first and offer a graceful fallback (e.g. a disabled button with
  /// a tooltip) rather than calling this blindly.
  Future<void> speakBangla(String text) => speak(text, languageCode: 'bn-BD');

  Future<void> stop() => _flutterTts.stop();
}