plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.ironbook.ironbook_gm"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.ironbook.ironbook_gm"
        minSdk = 24
        multiDexEnabled = true
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val keyAliasVal = keystoreProperties["keyAlias"] as String?
    val keyPasswordVal = keystoreProperties["keyPassword"] as String?
    val storeFileVal = keystoreProperties["storeFile"] as String?
    val storePasswordVal = keystoreProperties["storePassword"] as String?

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists() && storeFileVal != null) {
                keyAlias = keyAliasVal
                keyPassword = keyPasswordVal
                storeFile = file(storeFileVal)
                storePassword = storePasswordVal
            }
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists() && storeFileVal != null) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation(platform("com.google.firebase:firebase-bom:33.10.0"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-analytics")
}

flutter {
    source = "../.."
}
