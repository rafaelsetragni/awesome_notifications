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
            // The Flutter-free engine (me.carda.android_awn_core) lives in
            // src/main/kotlin so it ships with the package; native/android links
            // to it. Later it can be split into its own Maven Central module.
            java.srcDirs("src/main/kotlin")
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
    // MediaStyle + MediaSessionCompat (the MediaPlayer layout).
    implementation("androidx.media:media:1.7.0")

    testImplementation("junit:junit:4.13.2")
    testImplementation("org.mockito:mockito-core:5.14.2")
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
// Robolectric loads the classes in its own sandbox classloader; the agent
// only counts them with includeNoLocationClasses.
tasks.withType<Test>().configureEach {
    extensions.configure<JacocoTaskExtension> {
        isIncludeNoLocationClasses = true
        excludes = listOf("jdk.internal.*")
    }
}

tasks.register<JacocoReport>("awnCoverageReport") {
    dependsOn("testDebugUnitTest")
    executionData.setFrom(
        fileTree(layout.buildDirectory).include("**/testDebugUnitTest.exec", "jacoco/*.exec")
    )
    classDirectories.setFrom(
        fileTree(layout.buildDirectory.dir("tmp/kotlin-classes/debug"))
    )
    sourceDirectories.setFrom(
        files("src/main/kotlin")
    )
    reports {
        xml.required.set(true)
        html.required.set(true)
    }
}
