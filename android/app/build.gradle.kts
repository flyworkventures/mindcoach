import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Key properties dosyasını yükle (varsa)
// Önce android/app/key.properties'i kontrol et (app modülü içinde)
// Yoksa android/key.properties'i dene (root project'te)
val keystoreProperties = Properties()
val keystorePropertiesFile = file("$projectDir/key.properties").takeIf { it.exists() } 
    ?: rootProject.file("key.properties").takeIf { it.exists() }
    
if (keystorePropertiesFile != null && keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    println("✅ [Gradle] Keystore properties loaded from: ${keystorePropertiesFile.absolutePath}")
} else {
    println("⚠️ [Gradle] Keystore properties file not found, using debug signing")
}

android {
    namespace = "com.flywork.mindcoach"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Core library desugaring for Java 8+ APIs
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.flywork.mindcoach"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // MultiDex support (if needed for large apps)
        multiDexEnabled = true
    }

    // Signing configs
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile != null && keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                // storeFile path'i key.properties'de göreli veya mutlak yol olabilir
                val storeFilePath = keystoreProperties["storeFile"] as String
                storeFile = if (storeFilePath.startsWith("/")) {
                    // Mutlak yol
                    file(storeFilePath)
                } else {
                    // Göreli yol - key.properties dosyasının bulunduğu dizinden başlar
                    // key.properties app/ klasöründe, keystore de aynı yerde
                    val keystoreDir = keystorePropertiesFile!!.parentFile ?: projectDir
                    val cleanPath = storeFilePath.replace("./", "")
                    file("${keystoreDir.absolutePath}/${cleanPath}")
                }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            
            signingConfig = if (keystorePropertiesFile != null && keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            
            // Release build optimizasyonları
            isMinifyEnabled = false // ProGuard/R8 minification (gerekirse true yapın)
            isShrinkResources = false // Kullanılmayan kaynakları kaldır (isMinifyEnabled true olmalı)
            
            // ProGuard rules (minification aktifse)
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
            
            // Debugging için (production'da false olmalı)
            isDebuggable = false
            
            // JNI debug symbols (crash reporting için)
            ndk {
                debugSymbolLevel = "FULL"
            }
        }
        debug {
            isDebuggable = true
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
    
    // Packaging options
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring for Java 8+ APIs (required by flutter_local_notifications)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // Google Sign-In (already included via google_sign_in Flutter plugin)
    // No additional dependencies needed
    
    // Facebook SDK (already included via flutter_facebook_auth Flutter plugin)
    // No additional dependencies needed
    
    // Apple Sign-In is iOS only, not available on Android
}
