# Flutter embedding keeps plugin classes reflectively.
-keep class io.flutter.** { *; }
-keep class plugin.** { *; }
# local_auth uses biometric prompt APIs via the embedding — keep wrappers.
-keep class androidx.biometric.** { *; }
# Play Core deferred-component classes are referenced by the Flutter
# embedding but unused in APK builds — suppress missing-class warnings.
-dontwarn com.google.android.play.core.**
