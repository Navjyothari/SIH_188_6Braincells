# Evidence preview orientation — 19 September 2026

The user confirmed that version 0.1.1 captured the altered fictional specimen on a Samsung Note 10 Lite, read `TEST558198` / `TEST558199`, showed REVIEW_REQUIRED, and saved encrypted evidence. Their attached photograph showed that the original-capture preview was upside down after photographing in landscape orientation.

## Cause and fix

`Image.memory` honors JPEG EXIF orientation. The evidence widget additionally rotated by the saved CameraX `rotationDegrees`, applying orientation twice to tagged JPEGs. The OCR path uses Android BitmapFactory plus CameraX rotation, which is why OCR could be correct while the evidence preview was wrong.

Version `0.1.2+3` creates an in-memory display copy without EXIF APP1 metadata and applies the saved CameraX rotation once. It copies JPEG compressed pixel data and all unrelated segments verbatim. The encrypted original, original EXIF, capture time, OCR, result and stored rotation are not rewritten. Both new captures and existing saved records use the corrected widget; there is no storage migration or recapture requirement.

This does not modify the user's attached photograph. Only the app's evidence renderer is changed.

## Verification

- Four deterministic JPEG orientations: 0, 90, 180 and 270 degrees.
- Rendered red/green/blue/yellow corner positions checked with and without EXIF metadata, covering both landscape directions.
- Original input bytes remain identical; display JPEG pixels match the corresponding untagged fixture exactly.
- Unrelated JPEG metadata is preserved, and malformed/non-JPEG input is not rewritten.
- All 14 focused orientation tests passed; static analysis reported no issues.
- Full Flutter regression suite: 29 passed.
- Version 0.1.2 release APK passed the offline emulator capture → OCR → encrypted save → force-stop → reopen regression, record `18cd62b4-3a57-415b-b8df-e6c2ca4e7ad5`.
- Compiled release manifest still excludes INTERNET permission.
- The in-place Samsung update reported `Success`, followed by a successful cold launch. Existing app data was retained. On resuming on 20 September, no device was connected; physical confirmation of the corrected preview remains pending.

Release APK SHA-256: `0b667d9faf74c917b1eee007b79b28ffc1de1384c032e52d95f12eb62c3f5de4`.

References: [CameraX in-memory image rotation contract](https://developer.android.com/reference/androidx/camera/core/ImageCapture.OnImageCapturedCallback), [Flutter engine EXIF-aware decoding](https://chromium.googlesource.com/external/github.com/flutter/engine/+/refs/heads/flutter-3.12-candidate.2/lib/ui/painting/image_generator.cc).

Physical verification: reopen the previously saved upside-down record after updating, then capture with the phone tilted left and right. The preview should remain upright. This remains distinct from the fresh-install airplane-mode ship gate.
