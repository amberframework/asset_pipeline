# Android Material Host

This host is the Android validation shell for the `asset_pipeline` Material
phase. It is intentionally scoped to `asset_pipeline` ownership:

- renderer behavior lives in `src/ui/renderers/android_renderer.cr`
- shared validation truth lives under `docs/android-material-validation/`
- this host owns the Android showcase shell, capture entry point, and renderer
  mount surface

The Crystal/JNI render mount is wired. The host launches renderer-backed Android
studies, applies the requested appearance, and records the study status that is
meant to match the validation ledger. The ledger still decides whether a study
is accepted; the host should not be treated as a shortcut around that review.

## Local expectations

- canonical SDK root on this machine:
  `/opt/homebrew/share/android-commandlinetools`
- recommended AVDs:
  - `crystal_test`
  - `test_api35`
  - `Pixel_3a_API_34_extension_level_7_arm64-v8a`
  - `pixel_tablet_api35`

## Build

```bash
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export ANDROID_HOME="/opt/homebrew/share/android-commandlinetools"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
cd samples/cross_platform/android_host
./gradlew :app:assembleDebug
adb -s emulator-5554 install -r app/build/outputs/apk/debug/app-debug.apk
```

The host accepts these activity extras:

- `study_slug`
- `study_appearance`
- `study_story`

Example launch:

```bash
adb shell am start -S \
  -n dev.assetpipeline.androidhost/.MainActivity \
  --es study_slug buttons \
  --es study_appearance light
```

Current showcase studies include:

- `buttons`
- `text-fields`
- `cards`
- `dialogs`
- `app-bars`
- `selection-controls`
- `transient-surfaces`
- `share-color`
- `webview`
- `map-view`
- `video-player`
- `chart-view`
- `interaction-smoke` for internal callback verification only

## Capture Workflow

Use the shared runner from the repo root so screenshot naming, renderer-mount
readiness checks, splash-screen exit checks, and serial-specific host
installation stay consistent with the Android validation ledger.

```bash
./scripts/run_android_material_tests.sh --serial emulator-5554 --device-role phone --appearance both
./scripts/run_android_material_tests.sh --serial emulator-5556 --device-role tablet --appearance both --skip-build
```

Helpful flags:

- `--only buttons,text-fields`
- `--appearance light|dark|both`
- `--device-role phone|tablet`
- `--skip-build` to reuse the installed host APK
  This assumes the currently installed APK on the target serial already
  matches your local source tree. If you changed `android_material_bridge.cr`,
  JNI bridge code, or Kotlin host files, rebuild and reinstall before using
  `--skip-build`.
