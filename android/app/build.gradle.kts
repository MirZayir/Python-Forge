plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.python_forge"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.python_forge"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    packaging {
        jniLibs {
            // serious_python loads the CPython runtime from the extracted
            // native library directory (/lib/<abi>/libpythonbundle.so).
            // Without legacy packaging AGP keeps .so files compressed inside
            // the APK, they are never extracted, and Python cannot start.
            useLegacyPackaging = true
        }
    }

    val releaseStoreFile = providers.gradleProperty("PYTHON_FORGE_UPLOAD_STORE_FILE").orNull
    val releaseStorePassword = providers.gradleProperty("PYTHON_FORGE_UPLOAD_STORE_PASSWORD").orNull
    val releaseKeyAlias = providers.gradleProperty("PYTHON_FORGE_UPLOAD_KEY_ALIAS").orNull
    val releaseKeyPassword = providers.gradleProperty("PYTHON_FORGE_UPLOAD_KEY_PASSWORD").orNull
    val hasReleaseSigning = listOf(
        releaseStoreFile,
        releaseStorePassword,
        releaseKeyAlias,
        releaseKeyPassword,
    ).all { !it.isNullOrBlank() }

    if (hasReleaseSigning) {
        signingConfigs {
            create("release") {
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            // Never ship a release artifact signed with Flutter/Android's
            // debug key. Configure the four PYTHON_FORGE_UPLOAD_* properties
            // in a private gradle.properties or CI secret store for release.
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = null
            }
        }
    }
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}
