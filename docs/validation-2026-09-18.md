# Phase 1 validation — 18 September 2026

**Superseded release finding (19 September):** version 0.1.0 fails OCR initialization in the optimized release build. The debug tests and release home-screen smoke test below did not cover the complete release capture flow. See `validation-2026-09-19.md` for the fix and actual release-flow regression.

Implementation tested by Codex. **Not an independent human acceptance sign-off.**

## Completed checks

| Check | Observed result | Scope |
|---|---|---|
| Flutter static analysis | No issues | Dart sources |
| Flutter tests | 14 passed | Ten separately specified parser cases, generated-specimen text expectations, three mocked UI workflow tests |
| Specimen regeneration | Byte-for-byte identical | Ten PNGs, text references and manifest, fixed seed and bundled font |
| Native Android instrumentation | 8 passed | Offline OCR for all ten images, camera JPEG in memory, app home launch, encrypted round-trip, ciphertext corruption/filename substitution rejection, incomplete-write exclusion, restart fixture preparation and UI reopening |
| Separate-process force-stop recovery | 1 passed | Force-stopped app, started a new instrumentation process, decrypted identical original/result envelope, selected the saved record in Flutter and saw REVIEW REQUIRED |
| APK model assets | Present | OCR detector/recognizer assets inspected in release ZIP |
| Release network capability | No INTERNET permission | Compiled release manifest inspected; CAMERA and ACCESS_NETWORK_STATE remain |
| Release build | Succeeded | Universal Android test APK, local debug signing key |
| Final release APK installation and cold launch | Succeeded offline | Emulator installation returned Success; Android launch reported Status: ok and LaunchState: COLD |

Deliverable: `build/app/outputs/flutter-apk/app-release.apk`, version `0.1.0+1`, minimum API 24, target API 36. SHA-256: `959a448d693c74b9628fedbab76839397306a47e3322ab16de1561748f3061b7`.

Test environment: Windows host; Flutter 3.44.1, Dart 3.12.1; Android emulator `sdk_gphone64_x86_64`, Android 16/API 36 family; airplane mode setting `1`, Wi-Fi setting `0`, mobile data disabled. The emulator was launched read-only from `Medium_Phone_API_36.1`. No physical phone was connected.

The OCR test feeds PNG specimens directly to bundled ML Kit. The camera test captures the emulator's virtual scene into an original JPEG. The UI recovery fixture is explicitly `INSTRUMENTATION_FIXTURE`, with an actual specimen PNG and separately specified result. These tests establish component behavior and integration points; they do **not** combine a physical photographed mismatch with a fresh offline installation into the full ship gate.

## Issues found and fixed during this run

- ML Kit read the initial V1 heading as `Vi` and truncated the red warning. Switched the fictional marker to `FICTIONAL PASSPORT ALPHA` and used high-contrast black header text. Kept strict parser matching; all ten direct-image OCR cases then passed.
- Corrected the camera permission callback signature for the installed AndroidX version.
- Replaced platform-version-dependent atomic-file behavior with an encrypted `.new` file, file sync, same-directory atomic rename, and directory sync. Incomplete writes remain outside the history listing.
- Corrected a UI test to query Flutter accessibility descriptions instead of Android native text. The screen itself launched successfully.
- Used a session-only short Java socket temporary directory to resolve the Windows Gradle loopback error.

## Still required

Follow `phase1-acceptance.md`: independently review all ten fixtures, fresh-install on a named physical phone with radios off, photograph an altered card, confirm the mismatch explanation, force-stop and reboot, and reopen exactly the same evidence. Permission-denial, low-storage and key-loss scenarios also need physical-device observations. Do not mark Phase 1 shipped until its camera/offline/reopen gate is recorded as PASS.

Only Android 16 emulator behavior has been exercised. API 24 is the packaged minimum, not a claim of testing every supported Android version. Default Flutter/Gradle compatibility deprecation warnings remain; they do not fail the current build.
