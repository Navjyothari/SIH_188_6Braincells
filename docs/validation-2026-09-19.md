# Release OCR fix — 19 September 2026

**Physical follow-up:** the user subsequently confirmed successful mismatch detection and encrypted saving on the Samsung. An upside-down evidence-preview issue was then reported; see `orientation-fix-2026-09-19.md` for version 0.1.2.

## Confirmed failure

The user reported successful camera preview followed by the generic capture/processing error on a Samsung Note 10 Lite, Android 13, One UI 5.1. App-process logs on the connected phone contained `NoSuchMethodException` for zero-argument constructors of:

- `com.google.mlkit.common.internal.CommonComponentRegistrar`
- `com.google.mlkit.vision.common.internal.VisionCommonRegistrar`
- `com.google.mlkit.vision.text.internal.TextRegistrar`

The release R8 removal report also listed those constructors as removed. This was an OCR initialization/packaging failure, not a denied camera permission. The previous Android tests ran against a debug APK; the old release smoke test checked only launch. Those checks missed this defect.

## Change

Version `0.1.1+2` adds a narrow R8 rule retaining ML Kit component-registrar classes and their public zero-argument constructors. Shrinking remains enabled; OCR stays bundled and release INTERNET permission stays absent. Camera permission, capture format, decode, size and OCR failures now have distinct user-visible error codes. No photo bytes or OCR text are logged by this diagnostic code.

See [Android's guidance for reflection constructor keep rules](https://developer.android.com/topic/performance/app-optimization/keep-rule-examples).

## Checks completed

- Flutter analysis: no issues.
- Flutter tests: 15 passed, including an OCR failure test ensuring it does not blame camera permission.
- Release APK rebuilt; R8 `seeds.txt` confirms all three public constructors retained.
- Updated the connected Samsung SM-N770F in place, preserving app data. Package manager confirmed `versionName=0.1.1`, `versionCode=2`; cold launch succeeded.
- **Unmodified release APK, offline emulator:** automated interaction with the real Flutter capture button and CameraX shutter completed OCR, encrypted saving, force-stop and reopening the identical record ID. Script: `tools/test_release_flow.py`. Observed PASS; record `cf084881-645d-499d-97cb-cea8770fd691`.
- The release regression uses the emulator's virtual scene, not an injected result or an artificial native test envelope. It proves processing and persistence; it does not demonstrate a photographed fictional mismatch.

The debug instrumentation APK cannot be used directly against an obfuscated release APK: its dependency names differ after shrinking. The standalone accessibility-based release regression avoids that mismatch and requires no change to the production APK.

APK SHA-256: `766559a10a07a7151b2563e0492e1bedeb98f739e56318207eedee3bb9d382d8`.

Physical-phone recapture and the original first-launch airplane-mode mismatch gate remain pending until observed. Updating an existing installation over wireless debugging does not count as a fresh offline installation.
