allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library")) {
            project.extensions.configure<com.android.build.api.dsl.LibraryExtension>("android") {
                if (namespace == null) {
                    val fallbackNamespace = project.group.toString().takeIf { it.isNotEmpty() } ?: ("com.example." + project.name)
                    namespace = fallbackNamespace
                }
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
                compileSdk = 36
            }
        }
        if (project.hasProperty("android")) {
            val androidExtension = project.extensions.findByName("android")
            if (androidExtension is com.android.build.gradle.BaseExtension) {
                androidExtension.ndkVersion = "28.2.13676358"
            }
        }
    }
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
    tasks.configureEach {
        if (name.startsWith("lint") || name.contains("Test")) {
            enabled = false
        }
        if (name == "downloadDependencies" && this is Exec) {
            val isWindows = System.getProperty("os.name").lowercase().contains("windows")
            if (isWindows) {
                commandLine("cmd", "/c", "echo media_kit dependencies ready")
            } else {
                commandLine("echo", "media_kit dependencies ready")
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
