# Elmore: Ending Pain 3.0 Port

<div style="text-align:center;font-size:1.2em;">

**Pure touch port for Android.**

</div>

This repository is a touch/mobile port of **Elmore: Ending Pain v3.0**, built on the Codename Engine framework. The playable mod is included in:

```
mods/Elmore_Ending_Pain/
```

## Engine

This port uses [Codename Engine](https://github.com/CodenameCrew/CodenameEngine).

The Android build workflow is in `.github/workflows/android.yml`. Pushing to `main` or running the workflow manually will build the release APK.

## Build locally

1. Install Haxe 4.3.7 and the libraries listed in `libs.xml`:
   ```
   haxe -cp commandline -D analyzer-optimize --run Main setup -s
   ```
2. Configure Lime for Android:
   ```
   haxelib run lime config ANDROID_SDK "$ANDROID_HOME"
   haxelib run lime config ANDROID_NDK_ROOT "$ANDROID_NDK_LATEST_HOME"
   haxelib run lime config JAVA_HOME "$JAVA_HOME_21_arm64"
   haxelib run lime config ANDROID_SETUP true
   ```
3. Build:
   ```
   haxelib run lime build android -ONLY_ARM64
   ```

The APK is written to `export/release/android/bin/app/build/outputs/apk/release/`.

## App identity

- App name: `Elmore: Ending Pain 3.0 Port`
- Application ID: `com.elmoreendingpain.port`
- Mod folder: `Elmore_Ending_Pain`
