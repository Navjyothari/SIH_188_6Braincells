# How to Switch Models: EdgeFace-S vs EdgeFace-XS

This guide explains how to switch between **EdgeFace-S** and **EdgeFace-XS** in this project.

---

## Quick Comparison: S vs XS

| Feature | EdgeFace-S (Current Default) | EdgeFace-XS |
| :--- | :---: | :---: |
| **Model ID** | `edgeface-s-gamma-05` | `edgeface-xs-gamma-06` |
| **Model Size** | **14.1 MB** | **6.9 MB** |
| **Parameters** | 3.65 Million | 1.77 Million |
| **FLOPs (Inference Complexity)** | 306 MFLOPs | 154 MFLOPs |
| **Tested Phone Latency (Nord CE4)** | ~880 ms | ~830 ms |
| **Document Match Confidence** | **Higher (~0.83 – 0.85)** | **~0.80 – 0.82** |
| **Best Used For** | Real-world IDs, aged photos, border checkpoints | Ultra-constrained devices (1–2 GB RAM) |

---

## Method 1: The 1-Command Automatic Way (Easiest)

We provide a helper script that does everything automatically in 1 second.

Open your terminal in the project root (`SIH_188_6Braincells`) and run:

### To switch to EdgeFace-XS:
```bash
python scripts/switch_model.py xs
```

### To switch back to EdgeFace-S:
```bash
python scripts/switch_model.py s
```

**That's it!** The script:
1. Checks the SHA-256 fingerprint of the model file to ensure it's not corrupted.
2. Copies `edgeface.onnx` and `edgeface_manifest.json` into the Android assets.
3. Automatically updates the configuration files and Kotlin code.

Then simply run your app:
```bash
flutter run
```

---

## Method 2: The Manual Step-by-Step Way

If you ever want to do it manually without using the script, follow these 4 simple steps:

### Step 1: Locate the Model Files
All pre-exported, verified model packages live inside the `release-assets/` folder:
- **EdgeFace-S files:** [`release-assets/edgeface-s/`](file:///d:/GitHub/SIH_188_6Braincells/release-assets/edgeface-s)
- **EdgeFace-XS files:** [`release-assets/edgeface-xs/`](file:///d:/GitHub/SIH_188_6Braincells/release-assets/edgeface-xs)

Inside either folder, you will see two files:
1. `edgeface.onnx` (the actual neural network)
2. `edgeface_manifest.json` (the metadata and checksum file)

---

### Step 2: Copy Files to Android Assets
Copy both files from the model you want into:  
📁 [`android/app/src/main/assets/ml/`](file:///d:/GitHub/SIH_188_6Braincells/android/app/src/main/assets/ml)

*(Replace the existing `edgeface.onnx` and `edgeface_manifest.json` files).*

---

### Step 3: Update the Model Version in Kotlin
Open the file:  
📄 [`android/app/src/main/kotlin/com/sih188/borderdoc/face/FaceVerificationModule.kt`](file:///d:/GitHub/SIH_188_6Braincells/android/app/src/main/kotlin/com/sih188/borderdoc/face/FaceVerificationModule.kt)

Look at line 14:
- If using **EdgeFace-S**, it should be:
  ```kotlin
  companion object { const val MODEL_VERSION="edgeface_s_gamma_05-ce86851cfc37" }
  ```
- If using **EdgeFace-XS**, change it to:
  ```kotlin
  companion object { const val MODEL_VERSION="edgeface_xs_gamma_06-ce86851cfc37" }
  ```

---

### Step 4: Update the SHA-256 Checksum in `edgeface_evaluation.json`
Open the file:  
📄 [`android/app/src/main/assets/ml/edgeface_evaluation.json`](file:///d:/GitHub/SIH_188_6Braincells/android/app/src/main/assets/ml/edgeface_evaluation.json)

Change the `"onnxSha256"` field to match your chosen model:
- **EdgeFace-S SHA-256:**
  ```json
  "onnxSha256": "a051f4157258f1be4260dcab03f2c551715df9904f995bab9c480fe22fd7966b"
  ```
- **EdgeFace-XS SHA-256:**
  ```json
  "onnxSha256": "45083a8c4515edb2a9464374a948c4647ad964bf4d0b623c05f83a0a3e274472"
  ```

---

### Step 5: Build and Run
```bash
flutter run
```
You are all set!
