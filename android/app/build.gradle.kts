plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "dev.local.nihonkoe"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    val keystorePath: String? = System.getenv("ANDROID_KEYSTORE_PATH")

    defaultConfig {
        applicationId = "dev.local.nihonkoe"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Above every versionCode the Expo build used, so this installs over it.
        versionCode = 10000 + (System.getenv("VERSION_CODE")?.toIntOrNull() ?: 1)
        versionName = System.getenv("APP_VERSION")?.removePrefix("v") ?: flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePath != null) {
                storeFile = file(keystorePath)
                storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("ANDROID_KEY_ALIAS")
                keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = when {
                keystorePath != null -> signingConfigs.getByName("release")
                // Never ship a debug-signed "release" from CI.
                System.getenv("CI") != null -> throw GradleException("ANDROID_KEYSTORE_PATH is required for CI release builds")
                else -> signingConfigs.getByName("debug")
            }
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
