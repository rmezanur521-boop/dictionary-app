import '../../domain/entities/history_entity.dart';

/// Detects whether input text is English or Bangla based on Unicode
/// script ranges. Bangla (Bengali) Unicode block is U+0980–U+09FF.
/// If the string contains any character in that range, we classify
/// it as Bangla; otherwise English. This is deliberately simple and
/// fast (no ML/heavy libs needed) — sufficient since the two scripts
/// never visually overlap.
class LanguageDetector {
  LanguageDetector._();

  static const int _banglaRangeStart = 0x0980;
  static const int _banglaRangeEnd = 0x09FF;

  static SearchLanguage detect(String input) {
    for (final rune in input.runes) {
      if (rune >= _banglaRangeStart && rune <= _banglaRangeEnd) {
        return SearchLanguage.bangla;
      }
    }
    return SearchLanguage.english;
  }

  static bool isBangla(String input) => detect(input) == SearchLanguage.bangla;
}