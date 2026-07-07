# Flutter / Dart
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# audio_service — MediaBrowserService & notification
-keep class com.ryanheise.audioservice.** { *; }

# just_audio — ExoPlayer internals accessed via reflection
-keep class com.google.android.exoplayer2.** { *; }
-keep class androidx.media3.** { *; }
-dontwarn com.google.android.exoplayer2.**
-dontwarn androidx.media3.**

# Dio / OkHttp / cookie_jar — network stack
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Keep Android media / audio classes used by the app
-keep class android.media.** { *; }
-keep class android.media.audiofx.Visualizer { *; }

# Prevent R8 from stripping annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses,EnclosingMethod
