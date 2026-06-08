import groovy.json.JsonSlurper

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val secretsFile = rootProject.file("../secrets.json")
val secrets = if (secretsFile.exists()) {
    @Suppress("UNCHECKED_CAST")
    JsonSlurper().parse(secretsFile) as Map<String, Any?>
} else {
    emptyMap()
}

fun secret(name: String): String =
    (secrets[name] as? String)
        ?: providers.environmentVariable(name).orNull
        ?: ""

android {
    namespace = "com.example.saferoad"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.saferoad"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Override the default debug signing config to use the shared keystore
        // checked into the repo, so every teammate gets the same SHA-1/256.
        getByName("debug") {
            storeFile = file("../debug.keystore")
            storePassword = secret("ANDROID_KEYSTORE_STORE_PASSWORD")
            keyAlias = "androiddebugkey"
            keyPassword = secret("ANDROID_KEYSTORE_KEY_PASSWORD")
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
