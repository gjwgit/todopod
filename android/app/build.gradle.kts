import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 20261030 gjw The Play Store upload key, following radiopod and innerpod.
//
// android/key.properties holds storePassword, keyPassword, keyAlias and
// storeFile, and storeFile names the keystore, resolved from android/app.
// NEITHER IS COMMITTED: android/.gitignore excludes key.properties, **/*.jks
// and **/*.keystore.
//
// package-android in the fluttertmpl installers workflow writes both from
// the ANDROID_* secrets before it builds, and this file reads them exactly
// as it does on a developer machine.

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Whether this machine can sign a release at all. A debug build needs no
// key.

val hasUploadKey = keystorePropertiesFile.exists()

android {
    namespace = "com.togaware.todopod"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.togaware.todopod"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // oidcRedirectScheme is required by oidc_android, which declares no
        // default for it, so the manifest merger fails without it.
	manifestPlaceholders.putAll(mapOf(
            "appAuthRedirectScheme" to "com.togaware.todopod",
            "oidcRedirectScheme" to "com.togaware.todopod"
        ))
    }

    // 20261030 gjw Created ONLY when key.properties is there. Gradle
    // evaluates this block during configuration, for every task, so reading
    // a missing property here would break debug builds too.

    signingConfigs {
        if (hasUploadKey) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // 20261030 gjw Was the DEBUG key, the Flutter template's
            // placeholder, which Play rejects and which a properly signed
            // version cannot later upgrade in place. No fallback to it when
            // key.properties is absent: findByName gives null and the
            // task-graph guard below fails the release build loudly.

            signingConfig = signingConfigs.findByName("release")
        }
    }
}

// 20261030 gjw Refuse a RELEASE build with no upload key, and only then.
// Checked against the task graph rather than at configuration, so a debug
// build is untouched on a machine with no keystore.

if (!hasUploadKey) {
    gradle.taskGraph.whenReady {
        if (allTasks.any { it.name.contains("Release") }) {
            throw GradleException(
                "android/key.properties is missing, so a release build " +
                    "cannot be signed with the upload key. It needs " +
                    "storePassword, keyPassword, keyAlias and storeFile.",
            )
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
