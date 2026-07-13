# sqflite — keep SQLite bindings from being stripped by R8
-keep class com.tekartik.sqflite.** { *; }

# flutter_tts
-keep class com.tundralabs.fluttertts.** { *; }

# Keep model classes used with reflection-free JSON parsing (we use
# manual fromMap/fromJson, so this is precautionary, not strictly
# required, but harmless to include)
-keep class dictionary_app.data.models.** { *; }

-dontwarn io.flutter.embedding.**