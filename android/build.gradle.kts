// Inject SERIOUS_PYTHON_SITE_PACKAGES environment variable
try {
    val processEnv = Class.forName("java.lang.ProcessEnvironment")
    val field = processEnv.getDeclaredField("theEnvironment")
    field.isAccessible = true
    @Suppress("UNCHECKED_CAST")
    val env = field.get(null) as MutableMap<String, String>
    env["SERIOUS_PYTHON_SITE_PACKAGES"] = "none"
    val caseInsensitiveField = processEnv.getDeclaredField("theCaseInsensitiveEnvironment")
    caseInsensitiveField.isAccessible = true
    @Suppress("UNCHECKED_CAST")
    val cider = caseInsensitiveField.get(null) as MutableMap<String, String>
    cider["SERIOUS_PYTHON_SITE_PACKAGES"] = "none"
} catch (_: Exception) {}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Redirect build directory to <project_root>/build
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val applySdkOverride = {
        if (plugins.hasPlugin("com.android.library") || plugins.hasPlugin("com.android.application")) {
            val android = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            android?.compileSdkVersion(36)
        }
    }

    if (state.executed) {
        applySdkOverride()
    } else {
        afterEvaluate {
            applySdkOverride()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}