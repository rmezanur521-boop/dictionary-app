# Release Checklist

## Before building
- [ ] `assets/db/dictionary_preloaded.db` present and contains the full ~50,000-word dataset
      (built via `tools/build_seed_db.py` — see Step 4)
- [ ] `assets/fonts/NotoSansBengali-Regular.ttf` and `-Bold.ttf` present (Step 3/11)
- [ ] `assets/images/app_icon.png` (1024x1024) present for launcher icon generation
- [ ] `android/key.properties` created from `key.properties.example` with real signing values
- [ ] Update `version:` in `pubspec.yaml` (format: `X.Y.Z+buildNumber`)
- [ ] Update `applicationId` in `android/app/build.gradle` to your real package name

## App icon generation
Add `flutter_launcher_icons` as a dev dependency, then:

flutter pub add --dev flutter_launcher_icons
flutter pub run flutter_launcher_icons

with this config block in `pubspec.yaml`:
```yaml
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/images/app_icon.png"
  adaptive_icon_background: "#2D5F6D"
  adaptive_icon_foreground: "assets/images/app_icon.png"
```

## Build commands
```bash
# Clean build
flutter clean
flutter pub get

# Verify everything compiles and tests pass first
flutter analyze
flutter test

# Build release APK (single, universal)
flutter build apk --release

# OR build split APKs per ABI (smaller downloads, recommended for distribution)
flutter build apk --release --split-per-abi

# OR build an App Bundle (required for Play Store distribution)
flutter build appbundle --release
```

Output locations:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- Split APKs: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (etc.)
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`

## Post-build verification
- [ ] Install the release APK on a physical device (not just emulator) — confirms real
      SQLite asset copy, TTS voice availability, and app icon render correctly
- [ ] Test fully offline (airplane mode) — search, favorites, history, categories, daily word
- [ ] Test online enrichment on a word not in the preloaded dataset
- [ ] Verify dark/light/system theme switching persists across app restart
- [ ] Check `flutter build apk --analyze-size` if APK size is a concern (50k-word DB is the
      largest single asset — expect the DB to dominate final APK size)