# Fictional Screen — Phase 1

Flutter Android prototype: **camera → bundled OCR → one number-consistency check → encrypted local evidence → reopen**. Only the visibly labelled `FICTIONAL PASSPORT ALPHA` training layout is supported. No real identity documents, government verification, CNN, face matching, clustering or dashboard.

**Ship gate is pending physical-device acceptance and independent fixture review.** See [the acceptance checklist](docs/phase1-acceptance.md). Implemented code and automated checks do not by themselves prove the camera/airplane-mode demonstration.

Current release OCR fix and regression results are recorded in [the 19 September validation report](docs/validation-2026-09-19.md). The [original report](docs/validation-2026-09-18.md) records earlier checks and their coverage gap.

Version 0.1.2 also fixes duplicate JPEG rotation in the original-capture preview, including existing saved records. See [orientation validation](docs/orientation-fix-2026-09-19.md).

## Build and run

Requires Flutter 3.44.1 / Dart 3.12.1, Android SDK 36, a compatible JDK (tested with Android Studio's JDK 21), and Android API 24+ device. Build-time package downloads require internet; runtime OCR is bundled.

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

The phase-1 release build uses a local debug signing key and is for testing only. Configure an owned release signing key before distribution. Do not uninstall/clear-data an installation containing evidence you need: its device-bound key cannot be restored.

On this Windows workstation, Java's Unix-domain socket path caused a Gradle loopback failure. The session-only workaround is:

```powershell
$env:JAVA_TOOL_OPTIONS='-Djdk.net.unixdomain.tmpdir=D:\tmp'
flutter build apk --release
```

Use an existing short writable temporary directory for that property. It is a local build workaround, not an Android app setting.

## Try the slice

Open or print [the altered specimen](specimens/01-altered.png) on another screen. Fresh-install and launch with airplane mode enabled and Wi-Fi/Bluetooth disabled. Capture the full card. Expect **REVIEW_REQUIRED**: `TEST558198` differs from `TEST558199`. After the encrypted-save confirmation, close/force-stop the app, reopen Saved evidence, and select the same record ID.

[The clean partner](specimens/01-clean.png) should return `NO_INCONSISTENCY_DETECTED`; this means only that both number fields agree. Government verification always remains `NOT_CONFIGURED`. Missing/ambiguous fields return `RECAPTURE`; an absent fictional-layout marker returns `UNSUPPORTED`.

## Code and handoffs

| Area | Files |
|---|---|
| Shared contract and parser | `docs/screening-result.schema.json`, `lib/screening.dart` |
| Camera, bundled OCR, native bridge | `android/app/src/main/kotlin/org/example/fictionalscreen/fictional_screen/` |
| Atomic encrypted storage | `EvidenceStore.kt` in that directory |
| Capture, processing, results, original evidence, history | `lib/main.dart` |
| Seeded fixtures and expected fields/alteration boxes | `specimens/manifest.json`, `tools/generate_specimens.py` |
| Separately authored parser cases and mocked workflow checks | `test/` |
| Native offline OCR, storage and recovery tests | `android/app/src/androidTest/` |

Each encrypted record contains original JPEG bytes with rotation metadata, UTC capture time, OCR text/boxes/engine, and the versioned screening result. AES-256-GCM uses a key held by Android Keystore. A single atomic file prevents completed records from containing only one half of the evidence. Record IDs are bound into authenticated data. No app-created plaintext capture files are written. Evidence is local, excluded from backup, and unavailable after key loss. Hardware-backed key storage is device-dependent; no such guarantee is claimed.

## Regenerate specimens

```powershell
python -m pip install -r tools/requirements.txt
python tools/generate_specimens.py
```

Seed: `1882026`; five clean/altered pairs; no real names, portraits, official seals or valid passport formats. Font and license are bundled in `tools/`. PNG dimensions and changed-region coordinates are in the manifest. Keep independent human review marked pending until another reviewer actually checks the ten images against their expected values.

## Native tests on a disposable emulator

```powershell
adb shell cmd connectivity airplane-mode enable
adb shell svc wifi disable
adb shell svc data disable
cd android
.\gradlew.bat :app:assembleDebug :app:assembleDebugAndroidTest
cd ..
adb install build/app/outputs/apk/debug/app-debug.apk
adb install build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
adb shell am instrument -w org.example.fictionalscreen.fictional_screen.test/androidx.test.runner.AndroidJUnitRunner
adb shell am force-stop org.example.fictionalscreen.fictional_screen
adb shell am instrument -w -e class org.example.fictionalscreen.fictional_screen.DeviceTests#verifyRestartEvidence org.example.fictionalscreen.fictional_screen.test/androidx.test.runner.AndroidJUnitRunner
```

Native tests deliberately use synthetic test payloads and direct specimen-image OCR, not a real camera capture. The restart test leaves one synthetic native-test envelope; use a disposable emulator installation, not an evidence-bearing phone. The ten Dart fixtures were authored separately from the image generator, but human independence is still pending.

Implementation references: [Google bundled text-recognition setup](https://developers.google.com/ml-kit/vision/text-recognition/v2/android), [CameraX in-memory capture](https://developer.android.com/media/camera/camerax/take-photo), [Android Keystore](https://developer.android.com/privacy-and-security/keystore).

## Release capture regression

Run this as well as debug tests: release shrinking can remove reflectively loaded OCR components. Start a disposable emulator, disable its radios, build the release APK and install it on that emulator. The following test operates the real app buttons, takes a virtual-scene photo, saves it, force-stops the app and reopens the same record:

```powershell
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-release.apk
python tools/test_release_flow.py --serial emulator-5554
```

Expected: `Release camera -> OCR -> encrypted save: PASS` followed by a JSON PASS and record ID. The script refuses physical-device serials so it cannot automatically photograph a user's surroundings. A virtual-scene result may be RECAPTURE or UNSUPPORTED; the separate physical specimen mismatch gate remains required.
