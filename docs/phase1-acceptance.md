# Phase 1 acceptance — 17–19 September

**Gate remains OPEN until independently checked on a physical Android phone.**
Automated text tests, mocked UI tests, emulator OCR and native storage tests have different scopes. None alone proves camera quality or a fresh physical-phone offline launch.

## Owner handoff

| Owner | Implemented handoff | Remaining acceptance |
|---|---|---|
| P1 | `lib/screening.dart`, versioned JSON schema; number-repeat mismatch; four states; government `NOT_CONFIGURED` | Review contract and narrow parsing policy |
| P2 | Flutter Android shell, native CameraX memory capture, bundled ML Kit Latin OCR | Fresh install and first launch in airplane mode on named phone |
| P3 | Ten deterministic PNGs, text references, seed 1882026, expected values and changed-region coordinates | Review printed readability |
| P4 | Android Keystore AES-256-GCM, original + OCR + result in one atomic encrypted envelope | Physical force-stop/reboot; full-storage and key-loss recovery checks |
| P5 | Capture guidance, progress, result explanation, original-image inspection, saved history, synthetic banners | Operate on phone; accessibility check |
| P6 | Ten manually authored parser cases separate from generator, generated-pair checks, UI failure tests, native tests | Independent human fixture sign-off and physical gate |

## Physical ship-gate procedure (P6)

Use a disposable test installation; uninstall/clear-data destroys its local encryption key and evidence. Do not erase a device's existing evidence to start this test.

1. Record tester, phone model, Android version, APK SHA-256, app version, date and specimen hash.
2. Independently inspect all ten PNGs against `specimens/manifest.json`: both values, expected state, visible fictional label, and alteration box. Record reviewer and date. Generator output is not independent review.
3. Print or display `01-altered.png` on a second screen, without resizing its text into illegibility.
4. Before first installation/launch, enable airplane mode; explicitly turn Wi-Fi and Bluetooth off. Install the APK over USB while leaving radios disabled.
5. Launch for the first time. Grant camera permission. Capture the complete specimen; **do not import OCR text or pre-seed app data**.
6. Expect `REVIEW_REQUIRED`, document number `TEST558198`, repeated number `TEST558199`, and an explanation naming both values. Government verification must read `NOT_CONFIGURED`.
7. Verify the original photo matches the specimen. Note the record ID. A result is complete only once encrypted save succeeds.
8. Force-stop/close the app, reopen it while offline, select the same record ID, and compare the original and explanation. Repeat after reboot and unlock.
9. Capture `01-clean.png`: expect `NO_INCONSISTENCY_DETECTED`, with the authenticity limitation. Deny camera permission, cancel capture, and photograph unreadable/unsupported inputs; no failure may appear as a successful consistency check.
10. Record PASS/FAIL, screenshots if permitted (app capture protection intentionally blocks screenshots), external observation notes, timings and any error. A failure keeps the gate open; defer every excluded feature.

| Evidence | Result | Device / reviewer / date |
|---|---|---|
| Ten fixtures independently checked | PENDING | |
| Fresh first launch offline | PENDING | |
| Camera → OCR → mismatch explanation | PENDING | |
| Original and result saved together | PENDING physical verification | |
| Force-stop and reboot reopen same evidence | PENDING physical verification | |
| Permission/error recovery | PENDING physical verification | |

## Security and scope limits

The device key is non-exportable through Android Keystore; hardware backing varies by device and is not claimed. App-private, credential-encrypted, no-backup storage is used (not Direct Boot storage). No plaintext capture files, external camera intents, galleries or thumbnails are created. The original JPEG bytes and rotation metadata are retained; OCR uses an in-memory bitmap. The app blocks OS screenshots/recents previews. Release INTERNET permission is explicitly removed.

AES-GCM authenticates each envelope and binds it to its filename. It does not detect deletion of entire records or provide an independently anchored audit trail; those are later-phase work. Uninstall, clear-data or key loss makes evidence unrecoverable. Do not claim operational readiness or authenticity detection.

An interrupted first write can leave an encrypted `.new` file; it is intentionally excluded from history. Fully committed records are synced before success is reported. Save failure retains the in-memory capture for retry, but process death before successful save loses that pending capture.

No CNN, face matching, clustering, dashboard, backend, or government integration belongs in this gate.
