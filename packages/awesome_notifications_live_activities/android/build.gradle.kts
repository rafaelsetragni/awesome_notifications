group = "me.carda.awesome_notifications_live_activities"
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
    id("jacoco")
}

android {
    namespace = "me.carda.awesome_notifications_live_activities"

    // Android 16 (API 36): ProgressStyle, promoted ongoing notifications.
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
    // registry and action routing without duplicating the engine.
    implementation(project(":awesome_notifications"))
    // NotificationCompat.ProgressStyle, setRequestPromotedOngoing,
    // setShortCriticalText and setChronometerCountDown (Android 16 Live Updates):
    // 1.17.0 is the first with them (the core itself stays on 1.13.1).
    implementation("androidx.core:core-ktx:1.17.0")

    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20240303")
    // 4.16: the first Robolectric that runs Android 16 (API 36).
    testImplementation("org.robolectric:robolectric:4.16")
    testImplementation("androidx.test:core-ktx:1.6.1")
}

// Unit-test coverage (JaCoCo). Robolectric loads the classes in its own
// sandbox classloader; the agent only counts them with includeNoLocationClasses.
tasks.withType<Test>().configureEach {
    extensions.configure<JacocoTaskExtension> {
        isIncludeNoLocationClasses = true
        excludes = listOf("jdk.internal.*")
    }
}

tasks.register<JacocoReport>("awnCoverageReport") {
    dependsOn("testDebugUnitTest")
    executionData.setFrom(fileTree(layout.buildDirectory).include("**/testDebugUnitTest.exec"))
    classDirectories.setFrom(
        fileTree(layout.buildDirectory.dir("tmp/kotlin-classes/debug")) { exclude("**/R.class", "**/R$*.class", "**/BuildConfig.class") }
    )
    sourceDirectories.setFrom(files("src/main/kotlin", "src/main/java"))
    reports {
        xml.required.set(true)
        html.required.set(false)
    }
}
