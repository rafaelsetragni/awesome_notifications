group = "me.carda.awesome_notifications"
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
    namespace = "me.carda.awesome_notifications"

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
            // The Flutter-free engine lives once at the repo root under
            // native/android/AndroidAwnCore and is compiled into the plugin from
            // here (single source of truth). Later it can be split into its own
            // Maven Central module without moving the sources.
            java.srcDirs(
                "src/main/kotlin",
                "../../../native/android/AndroidAwnCore/src/main/kotlin"
            )
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
            // Any incidental android framework method call returns a default
            // instead of throwing (we keep such calls out of the pure-logic tests).
            isReturnDefaultValues = true
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")

    testImplementation("junit:junit:4.13.2")
    testImplementation("org.mockito:mockito-core:5.0.0")
    // Real org.json so JsonUtils (map <-> JSON) can be unit-tested without
    // Robolectric; it shadows the throwing stubs in the mockable android.jar.
    testImplementation("org.json:json:20240303")
    // Robolectric provides a real Android runtime on the JVM (Context,
    // NotificationManager, Intent, …) for the framework-dependent tests.
    testImplementation("org.robolectric:robolectric:4.14.1")
    testImplementation("androidx.test:core-ktx:1.6.1")
}

// Manual JaCoCo report (AGP's built-in enableUnitTestCoverage is broken on this
// AGP version). The jacoco plugin attaches an on-the-fly agent to the unit-test
// task; this task turns the resulting .exec into an XML/HTML report over the
// AndroidAwnCore + plugin Kotlin classes.
//
// CAVEAT: classes exercised only under Robolectric (the engine, receivers,
// cancel registry, content build) read as 0% here — JaCoCo's on-the-fly agent
// does not see Robolectric's sandbox classloader. They ARE covered by passing
// tests; the pure-JVM-tested classes report their real coverage.
tasks.register<JacocoReport>("awnCoverageReport") {
    dependsOn("testDebugUnitTest")
    executionData.setFrom(
        fileTree(layout.buildDirectory).include("**/testDebugUnitTest.exec", "jacoco/*.exec")
    )
    classDirectories.setFrom(
        fileTree(layout.buildDirectory.dir("tmp/kotlin-classes/debug"))
    )
    sourceDirectories.setFrom(
        files(
            "src/main/kotlin",
            "../../../native/android/AndroidAwnCore/src/main/kotlin"
        )
    )
    reports {
        xml.required.set(true)
        html.required.set(true)
    }
}
