# Getting started: EdgeFace-S first

You do not need to install or learn the development tools yourself. The first target is S (`edgeface_s_gamma_05`); XS will be checked later.

## Your computer

Already available: Flutter, Android SDK/ADB, Git, Python and Android Studio's Java 21 runtime. The system's default Java is 25; Android builds use the installed Java 21 explicitly.

Model tools are installed and verified in `ml/edgeface/.venv`, separate from your existing Python environments. They include CPU-only PyTorch, torchvision, timm, NumPy, Pillow, ONNX and ONNX Runtime. A CUDA/NVIDIA installation is not required for this stage. The verified environment is recorded in `requirements-export-lock.txt`; the S export has passed.

## Your first phone test

Phone: **OnePlus Nord CE4**, connecting through **wireless debugging**.

1. Keep the computer and phone on the same Wi-Fi network.
2. Open phone Settings and search for **Wireless debugging** (inside Developer options).
3. Turn it on. When we are ready to pair, tap **Pair device with pairing code**.
4. Keep that dialog open. Supply its **IP address and port** and **pairing code** to the assistant, which can run the pairing command.
5. After pairing, the main Wireless debugging screen can show a different connection port. Supply that address too if the phone does not connect automatically.

You do not need to install Python, ONNX Runtime, Flutter, or Android Studio on the phone. The test APK contains the Android dependencies. The initial installation and tests have already completed without wiping existing app data. The steps above are only needed if wireless debugging must be reconnected.

Official wireless-debugging instructions: https://developer.android.com/tools/adb#connect-to-a-device-over-wi-fi

## What happens in order

1. Load the official S checkpoint on the computer.
2. Export it to ONNX and compare outputs with the original model. This checks conversion correctness, not whether two people match.
3. Run the same numerical fixtures on your Nord CE4 and compare outputs with the computer.
4. Test capture/alignment and measure latency/memory. Later, measure representative lower-end hardware as well.
5. Evaluate consented document-photo/selfie pairs and set thresholds. Only then enable MATCH/NO_MATCH results.
6. Evaluate XS later if needed, with separate measurements and thresholds.

The model's published non-commercial/share-alike terms and unresolved training-data terms are tracked in [the licence record](edgeface-licence-and-provenance.md). Local engineering results are not deployment approval. The full progress record is in [the checklist](edgeface-implementation-checklist.md).

## Completed on your computer and phone

S was exported from the official checkpoint and passed all four desktop parity cases. Your connected Nord CE4 passed seven Android tests, including the S embedding comparison and the bundled detector/five-point preprocessing path on a fictional portrait. No personal photos were used. The existing app was updated in place; no app-data wipe was requested.

No further tool installation is needed now. The main app still withholds recognition verdicts; the real S model is currently packaged only in the local instrumentation test APK. Live document/selfie evaluation, threshold calibration and lower-end performance qualification are the next stages.

Initial S warm embedding timing on this phone: p50 46.8 ms, p95 125.9 ms over 20 runs. These are model-only debug measurements; the full capture/comparison budget still needs testing. Detailed measurements are in [the validation record](edgeface-s-validation.json).
