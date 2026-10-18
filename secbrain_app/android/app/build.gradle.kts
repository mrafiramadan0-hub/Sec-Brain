plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // Firebase Google Services
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // Namespace = package untuk R class generation (sama dengan applicationId)
    namespace = "com.secbrain.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Wajib untuk flutter_local_notifications (Java 8 time APIs on older Android)
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // Application ID harus sama persis dengan package_name di google-services.json
        applicationId = "com.secbrain.app"

        // Firebase Auth minimal butuh API level 23 (Android 6.0)
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Mendukung multidex untuk app besar
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Menggunakan debug signing untuk sekarang (cukup untuk testing)
            // Ganti dengan release keystore sebelum publish ke Play Store
            signingConfig = signingConfigs.getByName("debug")

            // Aktifkan minify untuk APK lebih kecil di release
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            isDebuggable = true
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Wajib untuk flutter_local_notifications: desugaring Java 8+ time API
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
