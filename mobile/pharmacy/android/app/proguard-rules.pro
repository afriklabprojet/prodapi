# ═══════════════════════════════════════════════════════════════
# DR-PHARMA Pharmacy App — ProGuard / R8 Rules
# ═══════════════════════════════════════════════════════════════

# ───────────── Flutter Core ─────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# ───────────── Kotlin Metadata (R8 compat) ─────────────
-dontnote kotlin.**
-dontnote kotlinx.**

# ───────────── Firebase ─────────────
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }
-dontwarn com.google.firebase.messaging.**

# ───────────── Google Maps / Play Services ─────────────
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }
-keep class com.google.maps.** { *; }
-dontwarn com.google.maps.**

# ───────────── Infobip Mobile Messaging ─────────────
-keep class org.infobip.** { *; }
-dontwarn org.infobip.**
-keep class org.infobip.mobile.messaging.** { *; }
-keep interface org.infobip.mobile.messaging.** { *; }

# ───────────── Dio / OkHttp / Retrofit ─────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }
-keepattributes Signature
-keepattributes Exceptions
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# ───────────── Gson / JSON serialization ─────────────
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keep class com.google.gson.** { *; }

# ───────────── flutter_secure_storage / Tink Crypto ─────────────
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**
-keepclassmembers class * extends com.google.crypto.tink.shaded.protobuf.GeneratedMessageLite {
    <fields>;
}

# ───────────── gRPC (Firebase dependency) ─────────────
-dontwarn io.grpc.**
-keep class io.grpc.** { *; }

# ───────────── BouncyCastle Crypto ─────────────
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# ───────────── Play Core (deferred components) ─────────────
-dontwarn com.google.android.play.core.**

# ───────────── speech_to_text ─────────────
-keep class com.csdcorp.speech_to_text.** { *; }
-dontwarn com.csdcorp.speech_to_text.**

# ───────────── mobile_scanner / barcode ─────────────
-keep class dev.steenbakker.mobile_scanner.** { *; }
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# ───────────── image_picker ─────────────
-keep class io.flutter.plugins.imagepicker.** { *; }

# ───────────── connectivity_plus ─────────────
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# ───────────── geolocator ─────────────
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

# ───────────── local_auth ─────────────
-keep class io.flutter.plugins.localauth.** { *; }
-keep class androidx.biometric.** { *; }
-dontwarn androidx.biometric.**
-keep class androidx.core.hardware.fingerprint.** { *; }

# ───────────── flutter_local_notifications ─────────────
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# ───────────── url_launcher ─────────────
-keep class io.flutter.plugins.urllauncher.** { *; }

# ───────────── cached_network_image / Glide ─────────────
-keep class com.bumptech.glide.** { *; }
-dontwarn com.bumptech.glide.**

# ───────────── PDF / printing ─────────────
-keep class net.nfet.flutter.printing.** { *; }

# ───────────── package_info_plus ─────────────
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }

# ───────────── shared_preferences ─────────────
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# ───────────── path_provider ─────────────
-keep class io.flutter.plugins.pathprovider.** { *; }

# ───────────── AndroidX / Kotlin ─────────────
-keep class androidx.** { *; }
-dontwarn androidx.**
-keep class kotlin.** { *; }
-dontwarn kotlin.**
-keep class kotlinx.** { *; }
-dontwarn kotlinx.**

# ───────────── General safety ─────────────
# Keep classes that are accessed via reflection
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelables
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Keep Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R classes
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Don't warn about missing annotations
-dontwarn javax.annotation.**
-dontwarn sun.misc.Unsafe

