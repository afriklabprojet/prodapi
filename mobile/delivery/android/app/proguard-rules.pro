# DR-PHARMA Courier - ProGuard Rules
# Configuration pour optimiser et protéger l'APK de release

# Flutter & Dart
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# Shared Preferences
-keep class androidx.datastore.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Dio HTTP Client
-keep class com.squareup.okhttp3.** { *; }
-keep interface com.squareup.okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Gson (used by some plugins)
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Local Auth (Biometric)
-keep class androidx.biometric.** { *; }
-keep class androidx.core.hardware.fingerprint.** { *; }

# Workmanager
-keep class androidx.work.** { *; }
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context,androidx.work.WorkerParameters);
}

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# AndroidX Security (EncryptedSharedPreferences / MasterKey) — requis par FlutterSecureStorage
-keep class androidx.security.crypto.** { *; }
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

# Flutter Local Notifications
-keep class com.dexterous.** { *; }

# Google Maps
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.android.gms.maps.model.** { *; }

# Keep line numbers for crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep custom exceptions
-keep public class * extends java.lang.Exception

# R8 full mode compatibility
-dontwarn java.lang.invoke.StringConcatFactory

# Play Core (deferred components)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Camera
-keep class io.flutter.plugins.camera.** { *; }

# ============================================
# RULES AJOUTÉES — Audit sécurité mars 2026
# ============================================

# Home Widget — AppWidgetProvider déclaré dans le manifest
-keep class * extends android.appwidget.AppWidgetProvider { *; }
-keep class com.drpharma.courier.CourierStatusWidget { *; }

# Firebase Messaging — Service natif pour les push notifications
-keep class com.google.firebase.messaging.FirebaseMessagingService { *; }
-keep class * extends com.google.firebase.messaging.FirebaseMessagingService { *; }

# Flutter Local Notifications — BroadcastReceivers supplémentaires
-keep class androidx.core.app.NotificationCompat { *; }
-keep class androidx.core.app.NotificationCompat$* { *; }

# Connectivity Plus — Callbacks réseau natifs
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# Battery Plus — Récepteur BatteryManager
-keep class dev.fluttercommunity.plus.battery.** { *; }

# App Links / Deep Links — Intent filters (paiement callback)
-keep class android.content.Intent { *; }

# WebView — Utilisé pour le paiement JEKO
-keep class android.webkit.** { *; }

# Kotlin serialization & coroutines (utilisé par certains plugins)
-dontwarn kotlinx.serialization.**
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# NOTE: Hive est pur Dart — AUCUNE règle ProGuard nécessaire.
# R8 ne minifie que le bytecode Java/Kotlin, pas le code Dart.
