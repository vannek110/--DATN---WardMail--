plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

/*
 * ============================================================================
 * ANDROID BUILD CONFIGURATION MODULE
 * ============================================================================
 * Project: WardMail Client
 * Module: App Level Gradle
 * ----------------------------------------------------------------------------
 * VERSIONING STRATEGY:
 * - versionCode: Integer (Monotonically increasing). Used by Play Store.
 * - versionName: Semantic Versioning (Major.Minor.Patch).
 *
 * SIGNING CONFIGURATION NOTE:
 * The release signing config is currently commented out for local debugging.
 * For production builds, ensure the 'key.properties' file is present in the
 * root android directory and never committed to version control (security risk).
 *
 * DEPENDENCY MANAGEMENT:
 * Native Android dependencies are managed here. Please ensure compatibility
 * with AndroidX libraries to avoid runtime crashes.
 * ============================================================================
 */

android {
    namespace = "com.example.project"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.project"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.3")
}
