// Eliminar variable de entorno conflictiva ANDROID_PREFS_ROOT para evitar AndroidLocationsException en AGP
try {
    val processEnvironment = Class.forName("java.lang.ProcessEnvironment")
    val theEnvironmentField = processEnvironment.getDeclaredField("theEnvironment")
    theEnvironmentField.isAccessible = true
    val map = theEnvironmentField.get(null) as MutableMap<String, String>
    map.remove("ANDROID_PREFS_ROOT")
    
    val theCaseInsensitiveEnvironmentField = processEnvironment.getDeclaredField("theCaseInsensitiveEnvironment")
    theCaseInsensitiveEnvironmentField.isAccessible = true
    val ciMap = theCaseInsensitiveEnvironmentField.get(null) as MutableMap<String, String>
    ciMap.remove("ANDROID_PREFS_ROOT")
} catch (e: Exception) {
    // Ignorar si el entorno no permite modificación reflection
}

pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")
