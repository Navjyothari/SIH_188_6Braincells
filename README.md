# BorderDoc — AI-Powered Border Document Screening

This repository contains the Flutter/Android application and offline AI models for the BorderDoc screening prototype.

## Claims Register

**Important:** Please refer to the [Claims Register](docs/claims-register.md) for detailed definitions of the project's security constraints, privacy rules, and functional limits.

## Setup and Running (Flutter App)

The main application provides the complete checkpoint screening workflow, connecting the Flutter UI to the native Kotlin pipeline over `MethodChannel`.

### Prerequisites
- Flutter SDK (3.1.0+)
- Android SDK (API 34 compile, API 21+ min)
- Physical Android phone with USB debugging enabled (recommended), or an Android emulator with webcam redirection.

### Important Environment Gotchas
- **OneDrive Sync:** If your project directory is inside a cloud-synced folder (e.g. OneDrive Desktop), the Gradle build may hang indefinitely due to file-locking conflicts. **Pause OneDrive sync** before running `flutter run`.
- **NDK Version:** The face verification module requires NDK version `25.1.8937393`. If you face NDK missing errors during build, use Android Studio SDK Manager to install this specific version.
- **Build Directory Errors:** If you experience `app:build` missing directory errors, ensuring the app is properly cleaned (`flutter clean`) and sync is paused will resolve it.

### Launching the App
Ensure your phone is connected (`flutter devices`), then run:
```bash
flutter pub get
flutter run
```

## Testing Guide

### Part 1: On-Device Android / Flutter App Testing

#### Step 1: Document Capture
1. Point the **rear camera** at a document, ID specimen, or printed sample photograph.
2. Tap **Tap to open camera** to capture the document.
3. Review the capture. The full-resolution image is passed to the ML Kit detector to find the portrait.

#### Step 2: Live Selfie Capture
1. The **rear camera** (changed from front to isolate mirroring issues) opens automatically.
2. Align the subject's face in the frame and tap the Shutter Button.
3. Tap **Confirm & verify face** to run inference.
   - *Note:* Face verification can be skipped at any time. It is NEVER a mandatory blocking gate.

#### Step 3: Screening Evidence Screen
Review the results. The face verification card will display:
- **Status Badge:** `MATCH` (>= 0.75), `UNCERTAIN` (0.60 - 0.74), `NO MATCH` (< 0.60), or `NOT RUN`.
- **[DEBUG] Aligned Crops:** Tiny thumbnails of the exact 112x112 aligned face crops fed to the AI. Ensure they are perfectly centered.

### Part 2: Standalone Laptop / Webcam Validation

The standalone validation script lets you verify the MobileFaceNet TFLite model directly on your laptop webcam, completely independent of Flutter.

#### Prerequisites
Python 3.9+ installed on your laptop. Run:
```bash
pip install opencv-python tensorflow numpy pillow
```

#### How to Run
Test against your own photo (live 1:1 match test):
```bash
python scripts/test_face_webcam.py --model android/app/src/main/assets/ml/mobilefacenet.tflite --reference "path/to/your_photo.jpg"
```

Test using the bundled synthetic reference:
```bash
python scripts/test_face_webcam.py --model android/app/src/main/assets/ml/mobilefacenet.tflite --reference android/app/src/main/assets/ml/synthetic_reference_face.jpg
```

#### Live Operation
- A preview window opens. Wait for the **green bounding box** to detect your face.
- Press `[SPACE]` to capture and verify.
- Press `[ESC]` or `[Q]` to cancel.
- The terminal will print a clear structured box with the SIMILARITY SCORE.

#### Troubleshooting Webcam Test
- `[ERROR] Could not access webcam`: Use `--camera-index 1` to switch cameras, or close Teams/Zoom.
- `[FAIL-CLOSED] No face detected`: Ensure good lighting and look straight at the camera.

## Architecture & Privacy Invariants

1. **100% Offline**: All ML models (bundled ML Kit Face Detection + MobileFaceNet TFLite) execute strictly on-device. No network permissions are required.
2. **Zero Permanent Biometric Storage**: Captured images reside in transient app cache during the active session. No embedding vectors or biometric templates are persisted to disk.
3. **Fail-Closed & Decoupled**: Errors or unavailable models produce `NOT_RUN`. Face checks never suppress or alter OCR findings.