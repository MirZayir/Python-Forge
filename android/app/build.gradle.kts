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
            // serious_python packages the CPython bundle as a ZIP payload
            // with a .so filename. It must be extracted for loading, but it
            // is not an ELF object that llvm-strip can process.
            useLegacyPackaging = true
            keepDebugSymbols.add("**/libpythonbundle.so")
        }
    }

    fun configuredSecret(name: String) = providers.gradleProperty(name)
        .orElse(providers.environmentVariable(name))
        .orNull

    val releaseStoreFile = configuredSecret("PYTHON_FORGE_UPLOAD_STORE_FILE")
    val releaseStorePassword = configuredSecret("PYTHON_FORGE_UPLOAD_STORE_PASSWORD")
    val releaseKeyAlias = configuredSecret("PYTHON_FORGE_UPLOAD_KEY_ALIAS")
    val releaseKeyPassword = configuredSecret("PYTHON_FORGE_UPLOAD_KEY_PASSWORD")
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

val verifyPythonForgeReleaseSigning = tasks.register("verifyPythonForgeReleaseSigning") {
    doLast {
        val signingConfigured = providers.gradleProperty("PYTHON_FORGE_UPLOAD_STORE_FILE")
            .orElse(providers.environmentVariable("PYTHON_FORGE_UPLOAD_STORE_FILE"))
            .orNull
        val signingValuesPresent = listOf(
            signingConfigured,
            providers.gradleProperty("PYTHON_FORGE_UPLOAD_STORE_PASSWORD")
                .orElse(providers.environmentVariable("PYTHON_FORGE_UPLOAD_STORE_PASSWORD"))
                .orNull,
            providers.gradleProperty("PYTHON_FORGE_UPLOAD_KEY_ALIAS")
                .orElse(providers.environmentVariable("PYTHON_FORGE_UPLOAD_KEY_ALIAS"))
                .orNull,
            providers.gradleProperty("PYTHON_FORGE_UPLOAD_KEY_PASSWORD")
                .orElse(providers.environmentVariable("PYTHON_FORGE_UPLOAD_KEY_PASSWORD"))
                .orNull,
        ).all { !it.isNullOrBlank() }
        if (!signingValuesPresent) {
            throw GradleException(
                "Release signing is not configured. Set all PYTHON_FORGE_UPLOAD_* properties or environment variables; unsigned release artifacts are blocked.",
            )
        }
        if (!file(signingConfigured!!).isFile) {
            throw GradleException(
                "Release signing store file does not exist: $signingConfigured",
            )
        }
    }
}

tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    dependsOn(verifyPythonForgeReleaseSigning)
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}
