# ── RevenueCat ────────────────────────────────────────────────────────────────
-keepnames class androidx.navigation.fragment.NavHostFragment
-keepnames class com.revenuecat.purchases.Offering
-keepnames class com.revenuecat.purchases.**

# ── Hive (adaptadores gerados manualmente — sem code gen) ─────────────────────
-keepnames class com.multiversodigital.antigolpeia.**
-keep class ** extends com.hive.** { *; }
-keep class io.hive.** { *; }

# ── Supabase / Ktor / OkHttp ──────────────────────────────────────────────────
-keep class io.github.jan.supabase.** { *; }
-dontwarn io.github.jan.supabase.**
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-keep class okio.** { *; }
-dontwarn okio.**

# ── Kotlin serialization ──────────────────────────────────────────────────────
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt
-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class ** {
    @kotlinx.serialization.Serializable <methods>;
}

# ── Telephony plugin ──────────────────────────────────────────────────────────
-keep class com.shounakmulay.telephony.** { *; }
-dontwarn com.shounakmulay.telephony.**

# ── WorkManager ───────────────────────────────────────────────────────────────
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# ── Google APIs (Gmail) ───────────────────────────────────────────────────────
-keep class com.google.api.** { *; }
-dontwarn com.google.api.**
-keep class com.google.auth.** { *; }
-dontwarn com.google.auth.**

# ── Suprimir avisos do XML parser do Kotlin reflect ───────────────────────────
-dontwarn org.kxml2.io.KXmlParser**,org.kxml2.io.KXmlSerializer**

# ── Stack traces legíveis em crash reports ────────────────────────────────────
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
