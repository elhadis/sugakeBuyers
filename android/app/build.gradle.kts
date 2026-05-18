plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// --- DEFINE VERSION VARIABLES HERE ---
val flutterVersionCode = flutter.versionCode.toInt()
val flutterVersionName = flutter.versionName

android {
    namespace = "com.ragabaat.sugacke"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Use your registered Firebase Application ID
        applicationId = "com.ragabaat.sugacke"

        // Set flutter.minSdkVersion=21 in android/local.properties (not rewritten by Flutter migration).
        minSdk = flutter.minSdkVersion

        targetSdk = 34
        versionCode = flutterVersionCode
        versionName = flutterVersionName

        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
