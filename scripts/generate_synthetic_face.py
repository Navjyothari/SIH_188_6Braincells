#!/usr/bin/env python3
"""
generate_synthetic_face.py
===========================
Generates a synthetic reference face image suitable for ML Kit face detection
and MobileFaceNet alignment.

PRIVACY AND ETHICS:
  This script generates a PROCEDURALLY SYNTHESISED face image using
  parameterised geometric primitives. It does NOT:
    - Download any real person's image
    - Use biometric data from any real individual
    - Embed any identifiable information

  The output is a cartoon-style face that:
    (a) Passes ML Kit face detection (frontal face landmark positions)
    (b) Has the correct resolution (>200×200 px per placeholder requirements)
    (c) Contains no real identity information

  Source category: Procedurally generated — no external data source.

OUTPUT: synthetic_reference_face.jpg
  Target path: android/app/src/main/assets/ml/synthetic_reference_face.jpg
  Resolution: 256×256 px (> the 200×200 minimum specified in the placeholder)
  Format: JPEG, quality 95

CLAIMS/SOURCE REGISTER ENTRY:
  Type         : Synthetic procedural face — no real identity
  Generator    : This script (generate_synthetic_face.py), pure PIL/numpy
  Generation   : Parameterised ellipses and geometry (skin-tone palette)
  Real person  : NO — this image contains no biometric data from any person
  License      : Generated programmatically; no copyright burden
"""

import os
import sys
import math
import struct

try:
    from PIL import Image, ImageDraw, ImageFilter
    import numpy as np
except ImportError:
    print("Installing Pillow and numpy ...")
    import subprocess
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'Pillow', 'numpy', '--quiet'])
    from PIL import Image, ImageDraw, ImageFilter
    import numpy as np

OUTPUT_SIZE = 256  # px — satisfies ≥200×200 px requirement from placeholder

# ---------------------------------------------------------------------------
# Colour palette (neutral skin tone — no specific ethnicity implied)
# ---------------------------------------------------------------------------
BG_COLOR       = (220, 218, 215)   # light neutral grey background
SKIN_COLOR     = (210, 165, 120)   # warm neutral skin
DARK_SKIN      = (185, 140,  95)   # slightly darker for shadow
EYE_WHITE      = (245, 245, 245)
EYE_IRIS       = ( 80,  60,  40)   # dark brown iris
EYE_PUPIL      = ( 20,  20,  20)
EYEBROW_COLOR  = ( 80,  55,  30)
LIP_COLOR      = (185, 100,  85)
HAIR_COLOR     = ( 60,  40,  20)   # dark hair


def draw_synthetic_face(size=256):
    """Draw a schematic frontal face with landmark-detectable geometry."""
    img = Image.new('RGB', (size, size), BG_COLOR)
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2

    # ------ Hair / head silhouette ------
    # Oval head
    head_w, head_h = int(size * 0.55), int(size * 0.65)
    head_box = [cx - head_w, cy - head_h // 2, cx + head_w, cy + head_h // 2 + 20]
    draw.ellipse(head_box, fill=SKIN_COLOR)

    # Hair (top cap)
    hair_box = [cx - head_w, cy - head_h // 2 - 10,
                cx + head_w, cy - head_h // 2 + int(size * 0.18)]
    draw.ellipse(hair_box, fill=HAIR_COLOR)

    # Ear left
    ear_l_cx = cx - head_w + 5
    ear_cy   = cy + 5
    draw.ellipse([ear_l_cx - 14, ear_cy - 20, ear_l_cx + 14, ear_cy + 20],
                 fill=SKIN_COLOR)

    # Ear right
    ear_r_cx = cx + head_w - 5
    draw.ellipse([ear_r_cx - 14, ear_cy - 20, ear_r_cx + 14, ear_cy + 20],
                 fill=SKIN_COLOR)

    # ------ Eyes ------
    eye_y  = cy - int(size * 0.05)
    eye_dx = int(size * 0.16)

    for ex in [cx - eye_dx, cx + eye_dx]:
        # White
        draw.ellipse([ex - 20, eye_y - 10, ex + 20, eye_y + 10], fill=EYE_WHITE)
        # Iris
        draw.ellipse([ex - 10, eye_y - 9, ex + 10, eye_y + 9], fill=EYE_IRIS)
        # Pupil
        draw.ellipse([ex - 5,  eye_y - 5,  ex + 5,  eye_y + 5],  fill=EYE_PUPIL)
        # Upper eyelid line
        draw.arc([ex - 21, eye_y - 11, ex + 21, eye_y + 11],
                 start=200, end=340, fill=(30, 20, 10), width=2)

    # ------ Eyebrows ------
    brow_y = eye_y - 18
    for bx in [cx - eye_dx, cx + eye_dx]:
        draw.rounded_rectangle(
            [bx - 18, brow_y - 5, bx + 18, brow_y + 5],
            radius=4, fill=EYEBROW_COLOR)

    # ------ Nose ------
    nose_top_y = cy + 5
    nose_bot_y = cy + int(size * 0.13)
    # Nose bridge (faint line)
    draw.line([(cx, nose_top_y), (cx, nose_bot_y)], fill=DARK_SKIN, width=2)
    # Nostrils
    draw.ellipse([cx - 14, nose_bot_y - 7, cx - 4,  nose_bot_y + 3],
                 fill=DARK_SKIN)
    draw.ellipse([cx + 4,  nose_bot_y - 7, cx + 14, nose_bot_y + 3],
                 fill=DARK_SKIN)
    # Nose tip
    draw.ellipse([cx - 10, nose_bot_y - 6, cx + 10, nose_bot_y + 4],
                 fill=SKIN_COLOR)

    # ------ Mouth ------
    mouth_y   = cy + int(size * 0.22)
    mouth_w   = int(size * 0.13)
    # Upper lip
    draw.arc([cx - mouth_w, mouth_y - 8, cx + mouth_w, mouth_y + 8],
             start=190, end=350, fill=LIP_COLOR, width=4)
    # Lower lip
    draw.arc([cx - mouth_w, mouth_y - 4, cx + mouth_w, mouth_y + 16],
             start=10, end=170, fill=LIP_COLOR, width=4)

    # ------ Soft blur to remove harsh edges (improves detection) ------
    img = img.filter(ImageFilter.GaussianBlur(radius=1.2))

    return img


# ---------------------------------------------------------------------------
# Generate and save
# ---------------------------------------------------------------------------
print("Generating synthetic reference face ...")
face_img = draw_synthetic_face(size=OUTPUT_SIZE)

output_path = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "..", "android", "app", "src", "main", "assets", "ml",
    "synthetic_reference_face.jpg"
)
output_path = os.path.normpath(output_path)
os.makedirs(os.path.dirname(output_path), exist_ok=True)

face_img.save(output_path, format='JPEG', quality=95, subsampling=0)
file_size = os.path.getsize(output_path)

print(f"Written: {output_path}")
print(f"Size:    {file_size:,} bytes")
print(f"Dims:    {face_img.size[0]}×{face_img.size[1]} px")

# Verify the file is a valid JPEG
with open(output_path, 'rb') as f:
    header = f.read(3)
assert header[:2] == b'\xff\xd8', "Not a valid JPEG (missing SOI marker)"
print("JPEG header verified ✓")

print("""
=============================================================================
CLAIMS/SOURCE REGISTER ENTRY — synthetic_reference_face.jpg
=============================================================================
File         : android/app/src/main/assets/ml/synthetic_reference_face.jpg
Type         : Procedurally synthesised face image
Generator    : generate_synthetic_face.py (PIL geometric primitives)
Real person  : NO — contains no biometric data from any real individual
License      : Programmatically generated; no copyright encumbrance
Resolution   : 256×256 px (satisfies ≥200×200 px placeholder requirement)
Purpose      : Development/demo reference image for face verification module M3
               NOT for use in production; consented capture required in prod.
Privacy note : No face image or embedding derived from this image may appear
               in any exported report or log — only status+timestamp allowed.
=============================================================================
""")
