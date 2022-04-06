import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.gradle.jvm.tasks.Jar

plugins {
    base
    kotlin("jvm") version "1.3.21" apply false
    id("org.jmailen.kotlinter") version "1.20.1"
}

allprojects {
    group = "io.pleo"
    version = "1.0"

    repositories {
        mavenCentral()
        jcenter()
    }

    tasks.withType<KotlinCompile>().configureEach {
        kotlinOptions.jvmTarget = "1.8"
        kotlinOptions.suppressWarnings = true
    }

    tasks.withType<Test> {
        useJUnitPlatform()
    }
}


kotlinter {
    continuationIndentSize = 4
}