#!/usr/bin/env python3
"""
test_face_webcam.py
===================
Standalone, local webcam validation script for the M3 Face Verification Module.
Runs entirely on your laptop to sanity-check mobilefacenet.tflite before wiring
it into the full Android / Flutter application.

DEPENDENCIES:
    pip install opencv-python tensorflow numpy pillow

USAGE:
    python scripts/test_face_webcam.py --model android/app/src/main/assets/ml/mobilefacenet.tflite --reference path/to/my_photo.jpg

FLAGS:
    --model        (Required) Path to mobilefacenet.tflite
    --reference    (Required) Path to reference face photo (JPEG/PNG)
    --camera-index (Optional) Webcam device index (default: 0)
    --save-capture (Optional) Path to save captured webcam frame for debugging

CONTROLS IN WEBCAM PREVIEW:
    [SPACE] - Capture photo and proceed with verification
    [ESC]   - Cancel and exit
    [Q]     - Cancel and exit

THRESHOLDS & VERDICTS (Matching Kotlin FaceVerificationModule):
    score >= 0.75  --> MATCH
    score >= 0.60  --> UNCERTAIN
    score <  0.60  --> NO_MATCH
    Failure        --> NOT_RUN (fail-closed, never a guessed score)
"""

import argparse
import os
import sys
import numpy as np
from PIL import Image

# Ensure utf-8 output in Windows PowerShell / terminal
if hasattr(sys.stdout, 'reconfigure'):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
    except Exception:
        pass

# Module-level threshold constants matching Kotlin FaceVerificationModule.kt
THRESHOLD_MATCH = 0.75
THRESHOLD_UNCERTAIN = 0.60
INPUT_SIZE = 112
EXPECTED_EMBEDDING_SIZE = 192


def print_banner():
    print("=" * 65)
    print("      M3 FACE VERIFICATION - STANDALONE WEBCAM SANITY TEST      ")
    print("=" * 65)


def print_result_box(status: str, score: float | None, reason: str | None = None):
    print("\n" + "=" * 65)
    print(f"VERDICT         : {status}")
    if score is not None:
        print(f"SIMILARITY SCORE: {score:.4f}  (cosine similarity in [-1.0, 1.0])")
    else:
        print("SIMILARITY SCORE: None")
    print(f"THRESHOLDS      : MATCH >= {THRESHOLD_MATCH:.2f} | UNCERTAIN >= {THRESHOLD_UNCERTAIN:.2f} | NO_MATCH < {THRESHOLD_UNCERTAIN:.2f}")
    if reason:
        print(f"REASON          : {reason}")
    print("=" * 65)


def load_tflite_interpreter(model_path: str):
    """Loads and validates the TFLite model against expected tensor contracts."""
    if not os.path.exists(model_path):
        raise FileNotFoundError(f"Model file not found: {model_path}")

    import tensorflow as tf
    interpreter = tf.lite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()

    inp = interpreter.get_input_details()[0]
    out = interpreter.get_output_details()[0]

    inp_shape = inp['shape'].tolist()
    out_shape = out['shape'].tolist()

    if inp_shape != [1, INPUT_SIZE, INPUT_SIZE, 3]:
        print(f"[WARN] Unexpected input tensor shape: {inp_shape}, expected [1, {INPUT_SIZE}, {INPUT_SIZE}, 3]")

    if out_shape != [1, EXPECTED_EMBEDDING_SIZE]:
        print(f"[WARN] Unexpected output tensor shape: {out_shape}, expected [1, {EXPECTED_EMBEDDING_SIZE}]")

    return interpreter, inp['index'], out['index']


def get_face_cascade():
    """Initializes OpenCV Haar Cascade classifier."""
    import cv2
    cascade_path = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
    if not os.path.exists(cascade_path):
        raise RuntimeError(f"OpenCV Haar Cascade xml not found at {cascade_path}")
    cascade = cv2.CascadeClassifier(cascade_path)
    if cascade.empty():
        raise RuntimeError("Failed to load OpenCV face cascade classifier.")
    return cascade


def detect_and_crop_face(bgr_image: np.ndarray, cascade, margin_ratio: float = 0.10):
    """
    Detects face in BGR image using Haar Cascade and crops it with a margin.
    Returns (cropped_pil_image, bounding_box) or (None, None) if no face is found.
    """
    import cv2
    gray = cv2.cvtColor(bgr_image, cv2.COLOR_BGR2GRAY)
    faces = cascade.detectMultiScale(
        gray,
        scaleFactor=1.1,
        minNeighbors=5,
        minSize=(60, 60),
        flags=cv2.CASCADE_SCALE_IMAGE
    )

    if len(faces) == 0:
        return None, None

    # If multiple faces detected, choose the one with the largest bounding box area
    if len(faces) > 1:
        faces = sorted(faces, key=lambda f: f[2] * f[3], reverse=True)
        print(f"  [INFO] Detected {len(faces)} faces; selecting the primary (largest) face.")

    x, y, w, h = faces[0]
    img_h, img_w = bgr_image.shape[:2]

    m_w = int(margin_ratio * w)
    m_h = int(margin_ratio * h)

    x1 = max(0, x - m_w)
    y1 = max(0, y - m_h)
    x2 = min(img_w, x + w + m_w)
    y2 = min(img_h, y + h + m_h)

    crop_bgr = bgr_image[y1:y2, x1:x2]
    crop_rgb = cv2.cvtColor(crop_bgr, cv2.COLOR_BGR2RGB)
    pil_crop = Image.fromarray(crop_rgb)

    return pil_crop, (x, y, w, h)


def preprocess_crop(pil_crop: Image.Image) -> np.ndarray:
    """
    Resizes crop to 112x112 RGB and normalizes pixels to [-1, 1] via (pixel - 127.5) / 127.5.
    Exactly matches FaceEmbeddingRunner.kt and verify_face_assets.py.
    """
    resized = pil_crop.resize((INPUT_SIZE, INPUT_SIZE), Image.Resampling.BILINEAR)
    arr = np.array(resized, dtype=np.float32)
    norm_arr = (arr - 127.5) / 127.5
    tensor_input = np.expand_dims(norm_arr, axis=0)  # Shape: [1, 112, 112, 3]
    return tensor_input


def compute_embedding(interpreter, inp_index: int, out_index: int, input_tensor: np.ndarray) -> np.ndarray:
    """Executes TFLite inference and returns 192-d embedding."""
    interpreter.set_tensor(inp_index, input_tensor)
    interpreter.invoke()
    embedding = interpreter.get_tensor(out_index)[0]
    return embedding


def cosine_similarity(a: np.ndarray, b: np.ndarray) -> float:
    """Calculates cosine similarity between two 1-D vectors."""
    norm_a = float(np.linalg.norm(a))
    norm_b = float(np.linalg.norm(b))
    if norm_a == 0.0 or norm_b == 0.0:
        return 0.0
    return float(np.dot(a, b) / (norm_a * norm_b))


def capture_from_webcam(camera_index: int, cascade) -> np.ndarray | None:
    """
    Opens live webcam stream with bounding box preview.
    Press SPACE to capture, ESC / Q to cancel.
    """
    import cv2
    print(f"--> Opening webcam (device index: {camera_index})...")
    cap = cv2.VideoCapture(camera_index)

    if not cap.isOpened():
        print(f"[ERROR] Could not access webcam with device index {camera_index}.")
        print("        Tips: Check if another application is using the camera,")
        print("        or try passing '--camera-index 1' or '--camera-index 2'.")
        return None

    window_name = "M3 Face Verification - Live Capture (SPACE: Capture | ESC: Cancel)"
    cv2.namedWindow(window_name, cv2.WINDOW_NORMAL)
    cv2.resizeWindow(window_name, 720, 540)

    print("\n[PREVIEW ACTIVE]")
    print("  - Look directly at the camera with good lighting.")
    print("  - Press [SPACE] to capture your photo.")
    print("  - Press [ESC] or [Q] to cancel.")

    captured_frame = None

    try:
        while True:
            ret, frame = cap.read()
            if not ret or frame is None:
                print("[ERROR] Failed to read frame from webcam.")
                break

            display_frame = frame.copy()
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            faces = cascade.detectMultiScale(
                gray,
                scaleFactor=1.1,
                minNeighbors=5,
                minSize=(60, 60),
                flags=cv2.CASCADE_SCALE_IMAGE
            )

            # Draw bounding box and status text
            if len(faces) > 0:
                # Primary face in green
                x, y, w, h = faces[0]
                cv2.rectangle(display_frame, (x, y), (x + w, y + h), (0, 255, 0), 2)
                cv2.putText(
                    display_frame,
                    "Face Detected - Press [SPACE] to verify",
                    (20, 40),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    0.7,
                    (0, 255, 0),
                    2
                )
            else:
                cv2.putText(
                    display_frame,
                    "No Face Detected - Look at camera",
                    (20, 40),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    0.7,
                    (0, 0, 255),
                    2
                )

            # Subtitle instructions
            cv2.putText(
                display_frame,
                "[SPACE]: Capture | [ESC]/[Q]: Exit",
                (20, display_frame.shape[0] - 20),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.6,
                (255, 255, 255),
                1
            )

            cv2.imshow(window_name, display_frame)
            key = cv2.waitKey(1) & 0xFF

            if key == 32:  # SPACE bar
                captured_frame = frame.copy()
                print("  [✓] Frame captured!")
                break
            elif key == 27 or key == ord('q') or key == ord('Q'):  # ESC or Q
                print("  [!] Capture cancelled by user.")
                break

    finally:
        cap.release()
        cv2.destroyAllWindows()

    return captured_frame


def main():
    parser = argparse.ArgumentParser(
        description="Standalone local webcam sanity check for MobileFaceNet TFLite."
    )
    parser.add_argument(
        "--model",
        type=str,
        required=True,
        help="Path to mobilefacenet.tflite model file."
    )
    parser.add_argument(
        "--reference",
        type=str,
        required=True,
        help="Path to reference face photo (JPEG/PNG)."
    )
    parser.add_argument(
        "--camera-index",
        type=int,
        default=0,
        help="Webcam device index (default: 0)."
    )
    parser.add_argument(
        "--save-capture",
        type=str,
        default=None,
        help="Optional path to save captured webcam image for inspection."
    )

    args = parser.parse_args()
    print_banner()

    # 1. Validate paths
    if not os.path.isfile(args.model):
        print(f"[ERROR] Specified model file does not exist: {args.model}")
        print_result_box("NOT_RUN", None, f"Model file not found: {args.model}")
        sys.exit(1)

    if not os.path.isfile(args.reference):
        print(f"[ERROR] Specified reference image does not exist: {args.reference}")
        print_result_box("NOT_RUN", None, f"Reference image not found: {args.reference}")
        sys.exit(1)

    # 2. Initialize Haar Cascade face detector
    print("--> Initializing OpenCV Haar Cascade face detector...")
    try:
        cascade = get_face_cascade()
        print("  [✓] Haar Cascade loaded.")
    except Exception as e:
        print(f"[ERROR] Failed to initialize face detector: {e}")
        print_result_box("NOT_RUN", None, f"Face detector init error: {e}")
        sys.exit(1)

    # 3. Process reference image
    print(f"--> Reading reference image: {args.reference}")
    import cv2
    ref_bgr = cv2.imread(args.reference)
    if ref_bgr is None:
        print(f"[ERROR] OpenCV could not decode reference image: {args.reference}")
        print_result_box("NOT_RUN", None, "Reference image unreadable or corrupted")
        sys.exit(1)

    ref_crop, ref_box = detect_and_crop_face(ref_bgr, cascade)
    if ref_crop is None:
        print("[FAIL-CLOSED] No face detected in reference image!")
        print("             Ensure the reference photo is a clear, frontal portrait.")
        print_result_box("NOT_RUN", None, "No face detected in reference photo")
        sys.exit(0)

    print(f"  [✓] Reference face detected at box {ref_box} (w={ref_box[2]}, h={ref_box[3]})")

    # 4. Capture live webcam photo
    captured_bgr = capture_from_webcam(args.camera_index, cascade)
    if captured_bgr is None:
        print("[FAIL-CLOSED] No frame captured from webcam (camera unavailable or cancelled).")
        print_result_box("NOT_RUN", None, "Webcam capture was cancelled or camera unavailable")
        sys.exit(0)

    if args.save_capture:
        try:
            cv2.imwrite(args.save_capture, captured_bgr)
            print(f"  [✓] Captured frame saved to: {args.save_capture}")
        except Exception as e:
            print(f"  [WARN] Failed to save capture to {args.save_capture}: {e}")

    # 5. Detect face in captured frame
    print("--> Detecting face in captured webcam frame...")
    live_crop, live_box = detect_and_crop_face(captured_bgr, cascade)
    if live_crop is None:
        print("[FAIL-CLOSED] No face detected in captured webcam photo!")
        print("             Ensure your face is well-lit and facing the camera.")
        print_result_box("NOT_RUN", None, "No face detected in webcam photo")
        sys.exit(0)

    print(f"  [✓] Webcam face detected at box {live_box} (w={live_box[2]}, h={live_box[3]})")

    # 6. Load TFLite Model
    print(f"--> Loading TFLite model: {args.model}")
    try:
        interpreter, inp_idx, out_idx = load_tflite_interpreter(args.model)
        print("  [✓] TFLite Interpreter initialized successfully.")
    except Exception as e:
        print(f"[ERROR] Failed to load TFLite model: {e}")
        print_result_box("NOT_RUN", None, f"TFLite initialization error: {e}")
        sys.exit(1)

    # 7. Preprocess crops and compute embeddings
    print("--> Preprocessing crops to 112x112 RGB normalized [-1, 1]...")
    ref_tensor = preprocess_crop(ref_crop)
    live_tensor = preprocess_crop(live_crop)

    print("--> Running TFLite inference...")
    ref_emb = compute_embedding(interpreter, inp_idx, out_idx, ref_tensor)
    live_emb = compute_embedding(interpreter, inp_idx, out_idx, live_tensor)

    ref_norm = float(np.linalg.norm(ref_emb))
    live_norm = float(np.linalg.norm(live_emb))
    print(f"  [✓] Reference embedding computed (dim={ref_emb.shape[0]}, L2 norm={ref_norm:.4f})")
    print(f"  [✓] Webcam embedding computed    (dim={live_emb.shape[0]}, L2 norm={live_norm:.4f})")

    # 8. Compute Cosine Similarity
    score = cosine_similarity(ref_emb, live_emb)

    # 9. Determine Verdict based on strict project thresholds
    if score >= THRESHOLD_MATCH:
        status = "MATCH"
        reason = f"Cosine similarity {score:.4f} is at or above MATCH threshold ({THRESHOLD_MATCH:.2f})."
    elif score >= THRESHOLD_UNCERTAIN:
        status = "UNCERTAIN"
        reason = f"Cosine similarity {score:.4f} is in borderline band [{THRESHOLD_UNCERTAIN:.2f}, {THRESHOLD_MATCH:.2f}). Lighting or angle variation."
    else:
        status = "NO_MATCH"
        reason = f"Cosine similarity {score:.4f} is below UNCERTAIN threshold ({THRESHOLD_UNCERTAIN:.2f}). Distinct identities."

    print_result_box(status, score, reason)


if __name__ == '__main__':
    main()
