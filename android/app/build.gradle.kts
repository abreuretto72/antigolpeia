import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.firebase.appdistribution")
}

// ── Keystore (release signing) ────────────────────────────────────────────────
// Crie o arquivo android/key.properties com as credenciais do keystore.
// Nunca commite esse arquivo — ele está no .gitignore.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

kotlin {
    jvmToolchain(17)
}

android {
    namespace = "com.multiversodigital.antigolpeia"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.multiversodigital.antigolpeia"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias      = keystoreProperties["keyAlias"]      as String
                keyPassword   = keystoreProperties["keyPassword"]   as String
                storeFile     = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                // Fallback para debug enquanto key.properties não existir
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

// ── Firebase App Distribution ─────────────────────────────────────────────────
// Distribuição para beta testers sem passar pela Play Store.
// Uso: ./gradlew appDistributionUploadRelease
// Autenticação: firebase login (Firebase CLI) ou variável FIREBASE_TOKEN
firebaseAppDistribution {
    appId = "1:1052417579840:android:400e3ac9448bab488438a5"
    releaseNotes = "Beta AntiGolpeia v1.0 — análise de golpes com IA, monitor WhatsApp/SMS/Gmail, estatísticas. Reporte problemas: contato@multiversodigital.com.br"
    groups = "beta-testers"
}
