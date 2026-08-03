# ---- Flutter engine / embedding ----
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ---- Firebase (messaging / core) ----
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ---- Google Play Core (deferred components — referenced by Flutter engine,
#      not bundled; safe to ignore) ----
-dontwarn com.google.android.play.core.**

# ---- ML Kit text recognition (Tap Card scanner) ----
# The google_mlkit_text_recognition plugin references ALL five script
# recognisers (Latin, Chinese, Devanagari, Japanese, Korean) from one
# initialize() method, but each script ships as a separate artifact and we only
# depend on the Latin one. R8 then fails the release build on the four classes
# that genuinely aren't there ("Missing class ...TextRecognizerOptions").
# These are unreachable at runtime — the app only ever asks for Latin — so tell
# R8 to stop warning rather than pulling in ~4 unused models. If a non-Latin
# script is ever needed, add that artifact to dependencies and drop its line.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-keep class com.google.mlkit.vision.text.** { *; }

# ---- Kotlin ----
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings { <fields>; }

# ---- AndroidX ----
-dontwarn androidx.**

# ---- Keep native method names (JNI) ----
-keepclasseswithmembernames class * {
    native <methods>;
}

# ---- Keep Parcelables / Serializables (used by plugins passing data) ----
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ---- Keep enum values (reflection) ----
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ---- Keep annotations ----
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
