import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/tts_service.dart';

class TtsProvider extends ChangeNotifier {
  TtsProvider(this._ttsService) {
    _loadPreferences();
    _ttsService.checkBanglaSupport().then((support) {
      _banglaSupport = support;
      notifyListeners();
    });
  }

  final TtsService _ttsService;

  bool _isSpeaking = false;
  double _rate = 0.45;
  double _pitch = 1.0;
  TtsLanguageSupport _banglaSupport = TtsLanguageSupport.unknown;

  bool get isSpeaking => _isSpeaking;
  double get rate => _rate;
  double get pitch => _pitch;
  bool get isBanglaAvailable => _banglaSupport == TtsLanguageSupport.available;

  static const _prefRate = 'pref_tts_rate';
  static const _prefPitch = 'pref_tts_pitch';

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _rate = prefs.getDouble(_prefRate) ?? 0.45;
    _pitch = prefs.getDouble(_prefPitch) ?? 1.0;
    await _ttsService.setSpeechRate(_rate);
    await _ttsService.setPitch(_pitch);
    notifyListeners();
  }

  Future<void> setRate(double value) async {
    _rate = value;
    notifyListeners();
    await _ttsService.setSpeechRate(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefRate, value);
  }

  Future<void> setPitch(double value) async {
    _pitch = value;
    notifyListeners();
    await _ttsService.setPitch(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefPitch, value);
  }

  Future<void> speakEnglish(String text) async {
    if (text.trim().isEmpty) return;
    _isSpeaking = true;
    notifyListeners();
    try {
      await _ttsService.speakEnglish(text);
    } finally {
      await Future.delayed(const Duration(milliseconds: 400));
      _isSpeaking = false;
      notifyListeners();
    }
  }

  Future<void> speakBangla(String text) async {
    if (text.trim().isEmpty || !isBanglaAvailable) return;
    _isSpeaking = true;
    notifyListeners();
    try {
      await _ttsService.speakBangla(text);
    } finally {
      await Future.delayed(const Duration(milliseconds: 400));
      _isSpeaking = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _ttsService.stop();
    _isSpeaking = false;
    notifyListeners();
  }
}