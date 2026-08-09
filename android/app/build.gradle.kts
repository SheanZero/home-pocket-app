import java.security.KeyStore
import java.security.cert.X509Certificate
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Production credentials deliberately stay outside version control. Local
// releases use android/key.properties; CI can provide the equivalent values as
// environment variables. Debug builds do not require either source.
val releaseSigningProperties = Properties()
val releaseSigningPropertiesFile = rootProject.file("key.properties")
val phase61SigningEvidence =
    providers.gradleProperty("phase61SigningEvidence").orNull == "true"
if (!phase61SigningEvidence && releaseSigningPropertiesFile.exists()) {
    releaseSigningPropertiesFile.inputStream().use(releaseSigningProperties::load)
}

fun releaseSigningValue(propertyName: String, environmentName: String): String? =
    providers.environmentVariable(environmentName).orNull?.takeIf(String::isNotBlank)
        ?: releaseSigningProperties.getProperty(propertyName)?.takeIf(String::isNotBlank)

val releaseSigningValues = mapOf(
    "storeFile" to releaseSigningValue("storeFile", "ANDROID_KEYSTORE_PATH"),
    "storePassword" to releaseSigningValue("storePassword", "ANDROID_KEYSTORE_PASSWORD"),
    "keyAlias" to releaseSigningValue("keyAlias", "ANDROID_KEY_ALIAS"),
    "keyPassword" to releaseSigningValue("keyPassword", "ANDROID_KEY_PASSWORD"),
)

val missingReleaseSigningValues = releaseSigningValues
    .filterValues { it.isNullOrBlank() }
    .keys

fun requireReleaseSigning() {
    check(missingReleaseSigningValues.isEmpty()) {
        "Android release signing is not configured. Set ${missingReleaseSigningValues.joinToString()} " +
            "in ignored android/key.properties or provide ANDROID_KEYSTORE_PATH, " +
            "ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, and ANDROID_KEY_PASSWORD. " +
            "Release builds never use the debug keystore."
    }

    val keystoreFile = file(checkNotNull(releaseSigningValues.getValue("storeFile")))
    check(keystoreFile.isFile) {
        "Android release signing keystore does not exist: ${keystoreFile.path}"
    }
}

android {
    namespace = "com.sheanzero.happypocket.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.sheanzero.happypocket.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = releaseSigningValues["storeFile"]?.let(::file)
            storePassword = releaseSigningValues["storePassword"]
            keyAlias = releaseSigningValues["keyAlias"]
            keyPassword = releaseSigningValues["keyPassword"]
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

val verifyReleaseSigning = tasks.register("verifyReleaseSigning") {
    group = "verification"
    description = "Rejects missing or Android Debug signing for release artifacts."

    doLast {
        requireReleaseSigning()

        val keystore = KeyStore.getInstance(KeyStore.getDefaultType())
        val keystoreFile = file(checkNotNull(releaseSigningValues.getValue("storeFile")))
        val storePassword = checkNotNull(releaseSigningValues.getValue("storePassword"))
        val keyAlias = checkNotNull(releaseSigningValues.getValue("keyAlias"))
        keystoreFile.inputStream().use { input ->
            keystore.load(input, storePassword.toCharArray())
        }

        val certificate = keystore.getCertificate(keyAlias) as? X509Certificate
            ?: error("Android release signing alias '$keyAlias' does not resolve to an X.509 certificate.")
        check(!certificate.subjectX500Principal.name.contains("CN=Android Debug", ignoreCase = true)) {
            "Android release signing certificate is the Android Debug certificate. Use a production upload/app-signing key."
        }
    }
}

// Every APK/AAB packaging entry point must verify production signing first;
// debug and profile tasks remain usable without release credentials.
tasks.configureEach {
    if (name.matches(Regex("^(assemble|bundle|package).*Release$"))) {
        dependsOn(verifyReleaseSigning)
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
