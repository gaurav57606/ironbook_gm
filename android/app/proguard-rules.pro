# Proguard rules for Android
# This file handles obfuscation safety for critical plugins and models.

# Optimization attributes for Crashlytics and Debugging
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes Exceptions

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Local Auth
-keep class io.flutter.plugins.localauth.** { *; }

# Firebase (Auth, Analytics, Messaging, Crashlytics)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Play Integrity
-keep class com.google.android.play.core.integrity.** { *; }
-keep class com.google.android.play.core.common.** { *; }

# Drift / SQLite (Crucial for serialization and SQLCipher)
-keep class net.sqlcipher.** { *; }
-keep class sqlite3.** { *; }
-keep class org.sqlite.** { *; }
-dontwarn net.sqlcipher.**

# Workmanager
-keep class be.tramckas.workmanager.** { *; }
-keep class androidx.work.** { *; }

# Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Google Fonts
-keep class com.google.fonts.** { *; }

# Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Riverpod & Serialization
-keepclassmembers class * {
  @riverpod.annotation.* <fields>;
  @riverpod.annotation.* <methods>;
}

# Drift Generated Code (prevents R8 from stripping database accessors)
-keep class * extends net.simonvis.drift.GeneratedDatabase { *; }
-keep class * extends net.simonvis.drift.Table { *; }
-keep class * extends net.simonvis.drift.View { *; }
-keep class * implements net.simonvis.drift.Insertable { *; }
-keep class * implements net.simonvis.drift.Selectable { *; }
-keep class * implements net.simonvis.drift.DataClass { *; }

# Keep all models to prevent issues with reflection-based serialization in plugins
-keep class **.SyncWorkerState { *; }
-keep class **.MemberSnapshot { *; }
-keep class **.DomainEvent { *; }
-keep class **.EventType { *; }
-keep class **.Payment { *; }
-keep class **.Plan { *; }

# General Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.editing.** { *; }
