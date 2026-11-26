group = "me.carda.awesome_notifications_calls"
version = "1.0-SNAPSHOT"

buildscript {
    val kotlinVersion = "2.2.20"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.11.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
    id("kotlin-android")
}

android {
    namespace = "me.carda.awesome_notifications_calls"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin", "src/main/java")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            isReturnDefaultValues = true
            all {
                it.outputs.upToDateWhen { false }
                it.testLogging { events("passed", "skipped", "failed") }
            }
        }
    }
}

dependencies {
    // Depends on the core plugin module (which compiles AndroidAwnCore in), giving
    // the decorator access to the core's builder decorator chain, cancel-interceptor
    // registry, action routing and NotificationPerson without duplicating the engine.
    implementation(project(":awesome_notifications"))
    // NotificationCompat.CallStyle, ServiceCompat.
    implementation("androidx.core:core-ktx:1.13.1")
    // Telecom (CallsManager): Bluetooth / car / wearable call controls and audio
    // routing. Its own minSdk is 23; it is used from API 26 (see CallTelecom).
    implementation("androidx.core:core-telecom:1.0.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")

    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20240303")
    testImplementation("org.robolectric:robolectric:4.14.1")
    testImplementation("androidx.test:core-ktx:1.6.1")
}
