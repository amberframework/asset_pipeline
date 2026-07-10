plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

val crystalBridgeBuildScript = rootProject.file("build_crystal_lib.sh")

val buildCrystalBridge by tasks.registering(Exec::class) {
    group = "build"
    description = "Build the Crystal-backed Android renderer bridge for the host app."

    workingDir = rootProject.projectDir
    commandLine("bash", crystalBridgeBuildScript.absolutePath)
}

android {
    namespace = "dev.assetpipeline.androidhost"
    compileSdk = 35

    defaultConfig {
        applicationId = "dev.assetpipeline.androidhost"
        minSdk = 31
        targetSdk = 35
        versionCode = 1
        versionName = "0.1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables.useSupportLibrary = true
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        viewBinding = true
    }
}

tasks.matching { it.name == "preBuild" }.configureEach {
    dependsOn(buildCrystalBridge)
}

dependencies {
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.activity:activity-ktx:1.10.0")
    implementation("com.google.android.material:material:1.12.0")

    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.6.1")
    androidTestImplementation("androidx.test.uiautomator:uiautomator:2.3.0")
}
