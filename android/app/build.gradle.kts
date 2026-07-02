plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // ✅ penting untuk Firebase
}

android {
    namespace = "com.example.mental_health_app"

    // ✅ Gunakan SDK & NDK terbaru
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.mental_health_app"
        minSdk = 23 // ✅ wajib minimal 23 untuk Firebase modern
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            // Sementara gunakan debug signing agar bisa build
            signingConfig = signingConfigs.getByName("debug")

            // ✅ Nonaktifkan shrinking dulu agar tidak error
            isMinifyEnabled = false
            isShrinkResources = false

            // ✅ Tambahkan file ProGuard default (wajib meskipun tidak aktif)
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }

        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
