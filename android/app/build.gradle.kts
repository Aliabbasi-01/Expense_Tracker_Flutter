plugins {
    id("com.android.application")
    id("com.google.gms.google-services") apply false
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val androidApplicationId = "com.example.expense_tracker"
val firebaseConfig = file("google-services.json")
val hasMatchingFirebaseClient = if (firebaseConfig.isFile) {
    val config = groovy.json.JsonSlurper().parse(firebaseConfig) as? Map<*, *>
    val clients = config?.get("client") as? List<*>
    clients?.any { client ->
        val clientInfo = (client as? Map<*, *>)?.get("client_info") as? Map<*, *>
        val androidInfo =
            clientInfo?.get("android_client_info") as? Map<*, *>
        androidInfo?.get("package_name") == androidApplicationId
    } == true
} else {
    false
}

if (hasMatchingFirebaseClient) {
    apply(plugin = "com.google.gms.google-services")
} else {
    logger.warn(
        "Firebase is not configured for $androidApplicationId. " +
            "Add its matching google-services.json to android/app/ to enable sign-in and groups.",
    )
}

android {
    namespace = "com.example.expense_tracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = androidApplicationId
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
