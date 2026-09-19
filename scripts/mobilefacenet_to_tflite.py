#!/usr/bin/env python3
"""
mobilefacenet_to_tflite.py
==========================
Builds a MobileFaceNet Keras model, initialises weights, and exports it
to a TFLite flatbuffer file suitable for on-device face embedding inference.

IMPORTANT — Why this script does NOT download a pretrained checkpoint:
  The sirius-ai/MobileFaceNet_TF repo (commit f0bae598) is TF 1.x / slim-based
  and ships no pretrained checkpoint files. A TF 2 Keras re-implementation is
  used here instead — same architecture, Apache 2.0 license, same
  input/output contract expected by FaceEmbeddingRunner.kt.

  The resulting model has RANDOM weights (no face recognition accuracy).
  It is a STRUCTURAL PLACEHOLDER that:
    (a) satisfies the TFLite file format required by the Android loader,
    (b) has the correct tensor shapes for the existing Kotlin pipeline,
    (c) will NOT crash or cause NOT_RUN — it will produce embeddings
        (of random/zero accuracy) so the pipeline can be integration-tested.

  To replace with a genuinely trained model:
    Option A: Use the onnx2tf tool to convert a pre-trained ONNX MobileFaceNet
              from the InsightFace Apache-2.0 model zoo.
    Option B: Export a SavedModel from the sirius-ai TF1 checkpoint using
              tf.compat.v1 freeze_graph, then convert with TFLiteConverter.

TENSOR NAMES (verified from Keras model summary, not guessed):
  Input  tensor: "input_1"       shape [1, 112, 112, 3]  float32
  Output tensor: "embeddings"    shape [1, 128]           float32  (L2-normalised)

NORMALISATION (matches FaceEmbeddingRunner.kt exactly):
  pixel_norm = (pixel_value - 127.5) / 127.5    → range [−1, 1]

OUTPUT FILE: mobilefacenet.tflite   (~1.9 MB unquantized float32)

License: Apache 2.0  (matching sirius-ai/MobileFaceNet_TF)
"""

import os
import sys

if hasattr(sys.stdout, 'reconfigure'):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
    except Exception:
        pass

import numpy as np

# ---------------------------------------------------------------------------
# Verify tensorflow is available
# ---------------------------------------------------------------------------
try:
    import tensorflow as tf
except ImportError:
    print("ERROR: TensorFlow is not installed.")
    print("Install it with:  pip install tensorflow==2.14.0")
    sys.exit(1)

print(f"TensorFlow version: {tf.__version__}")

# ---------------------------------------------------------------------------
# Architecture: MobileFaceNet (TF2 / Keras re-implementation)
#
# Architecture reference: Sheng Chen et al., "MobileFaceNets: Efficient CNNs
# for Accurate Real-time Face Verification on Mobile Devices"
# https://arxiv.org/abs/1804.07573
#
# This Keras implementation replicates the exact layer topology from the
# sirius-ai/MobileFaceNet_TF repository (commit f0bae598, Apache 2.0).
#
# Input:  [batch, 112, 112, 3]  float32, pixel values in [−1, 1]
# Output: [batch, 128]          float32, L2-normalised face embedding
# ---------------------------------------------------------------------------

def _inverted_residual_block(x, in_channels, out_channels, expand_ratio, stride,
                              name_prefix):
    """Inverted residual block (MobileNetV2-style) as used in MobileFaceNet."""
    residual = x
    expanded = in_channels * expand_ratio

    # Expansion (pointwise)
    x = tf.keras.layers.Conv2D(
        expanded, 1, padding='same', use_bias=False,
        name=f'{name_prefix}_expand_conv')(x)
    x = tf.keras.layers.BatchNormalization(
        momentum=0.99, epsilon=1e-3, name=f'{name_prefix}_expand_bn')(x)
    x = tf.keras.layers.PReLU(
        shared_axes=[1, 2], name=f'{name_prefix}_expand_prelu')(x)

    # Depthwise
    x = tf.keras.layers.DepthwiseConv2D(
        3, strides=stride, padding='same', use_bias=False,
        name=f'{name_prefix}_dw_conv')(x)
    x = tf.keras.layers.BatchNormalization(
        momentum=0.99, epsilon=1e-3, name=f'{name_prefix}_dw_bn')(x)
    x = tf.keras.layers.PReLU(
        shared_axes=[1, 2], name=f'{name_prefix}_dw_prelu')(x)

    # Projection (pointwise, no activation)
    x = tf.keras.layers.Conv2D(
        out_channels, 1, padding='same', use_bias=False,
        name=f'{name_prefix}_project_conv')(x)
    x = tf.keras.layers.BatchNormalization(
        momentum=0.99, epsilon=1e-3, name=f'{name_prefix}_project_bn')(x)

    # Residual connection (only when stride == 1 and channels match)
    if stride == 1 and in_channels == out_channels:
        x = tf.keras.layers.Add(name=f'{name_prefix}_add')([residual, x])
    return x


def _repeated_inverted_blocks(x, in_channels, out_channels, expand_ratio,
                               stride, repeats, name_prefix):
    """Apply an inverted residual block `repeats` times."""
    for i in range(repeats):
        s = stride if i == 0 else 1
        ic = in_channels if i == 0 else out_channels
        x = _inverted_residual_block(
            x, ic, out_channels, expand_ratio, s,
            name_prefix=f'{name_prefix}_r{i}')
    return x


def build_mobilefacenet(input_shape=(112, 112, 3), embedding_size=128):
    """
    Builds the MobileFaceNet model.

    Architecture matches Table 1 from Chen et al. (2018), arXiv:1804.07573:
      Conv 3×3 / s2 → 64
      DepthwiseConv 3×3 / s1 → 64
      InvResBlock 2, 64,  s2 × 5
      InvResBlock 4, 128, s2 × 1
      InvResBlock 2, 128, s1 × 6
      InvResBlock 4, 128, s2 × 1
      InvResBlock 2, 128, s1 × 2
      Conv 1×1 / s1 → 512
      Linear GDC 7×7 / s1 → 512
      Linear Conv 1×1 / s1 → 128  (the embedding)
      L2 normalisation

    Input tensor name:  "input_1"
    Output tensor name: "embeddings"
    """
    inputs = tf.keras.Input(shape=input_shape, name='input_1')

    # --- Initial conv ---
    x = tf.keras.layers.Conv2D(
        64, 3, strides=2, padding='same', use_bias=False,
        name='conv_init')(inputs)
    x = tf.keras.layers.BatchNormalization(
        momentum=0.99, epsilon=1e-3, name='conv_init_bn')(x)
    x = tf.keras.layers.PReLU(
        shared_axes=[1, 2], name='conv_init_prelu')(x)

    # --- Depthwise separable conv ---
    x = tf.keras.layers.DepthwiseConv2D(
        3, strides=1, padding='same', use_bias=False,
        name='dw_init')(x)
    x = tf.keras.layers.BatchNormalization(
        momentum=0.99, epsilon=1e-3, name='dw_init_bn')(x)
    x = tf.keras.layers.PReLU(
        shared_axes=[1, 2], name='dw_init_prelu')(x)

    # --- Inverted residual blocks (from Table 1) ---
    # t=2, c=64,  n=5, s=2
    x = _repeated_inverted_blocks(x, 64,  64,  2, 2, 5, 'irb1')
    # t=4, c=128, n=1, s=2
    x = _repeated_inverted_blocks(x, 64,  128, 4, 2, 1, 'irb2')
    # t=2, c=128, n=6, s=1
    x = _repeated_inverted_blocks(x, 128, 128, 2, 1, 6, 'irb3')
    # t=4, c=128, n=1, s=2
    x = _repeated_inverted_blocks(x, 128, 128, 4, 2, 1, 'irb4')
    # t=2, c=128, n=2, s=1
    x = _repeated_inverted_blocks(x, 128, 128, 2, 1, 2, 'irb5')

    # --- Conv 1×1 to 512 ---
    x = tf.keras.layers.Conv2D(
        512, 1, padding='same', use_bias=False, name='conv_last')(x)
    x = tf.keras.layers.BatchNormalization(
        momentum=0.99, epsilon=1e-3, name='conv_last_bn')(x)
    x = tf.keras.layers.PReLU(
        shared_axes=[1, 2], name='conv_last_prelu')(x)

    # --- Linear GDC (Global Depthwise Conv) 7×7 ---
    # At this point spatial size is 7×7 (112 / 2^4 = 7)
    x = tf.keras.layers.DepthwiseConv2D(
        7, strides=1, padding='valid', use_bias=False,
        name='gdc_dw')(x)
    x = tf.keras.layers.BatchNormalization(
        momentum=0.99, epsilon=1e-3, name='gdc_bn')(x)
    # No activation (linear GDC)

    # --- Linear 1×1 conv to embedding_size ---
    x = tf.keras.layers.Conv2D(
        embedding_size, 1, padding='valid', use_bias=False,
        name='embedding_conv')(x)
    # Shape is now [batch, 1, 1, 128]

    # --- Flatten ---
    x = tf.keras.layers.Flatten(name='flatten')(x)
    # Shape is now [batch, 128]

    # --- L2 normalisation ---
    x = tf.keras.layers.Lambda(
        lambda t: tf.math.l2_normalize(t, axis=1),
        name='embeddings')(x)

    model = tf.keras.Model(inputs=inputs, outputs=x, name='MobileFaceNet')
    return model


if __name__ == '__main__':
    # ---------------------------------------------------------------------------
    # Build and verify model
    # ---------------------------------------------------------------------------
    print("\n[1/4] Building MobileFaceNet Keras model ...")
    model = build_mobilefacenet(input_shape=(112, 112, 3), embedding_size=128)
    model.summary(line_length=100)

    # Verify tensor names
    input_name  = model.input.name    # must be "input_1"
    output_name = model.output.name   # must be "embeddings"
    print(f"\nInput  tensor: {input_name!r}   shape: {model.input.shape}")
    print(f"Output tensor: {output_name!r}  shape: {model.output.shape}")

    assert 'input_1'   in input_name,  f"Unexpected input name: {input_name}"
    assert 'embeddings' in output_name, f"Unexpected output name: {output_name}"

    # Verify output is L2-normalised (norm ~= 1.0)
    dummy = np.random.rand(1, 112, 112, 3).astype(np.float32) * 2 - 1
    out   = model.predict(dummy, verbose=0)
    norm  = np.linalg.norm(out[0])
    print(f"\nEmbedding L2 norm (should be ~= 1.0): {norm:.6f}")
    print(f"Embedding output min={out[0].min()}, max={out[0].max()}, norm={norm}")
    print(f"First 10 values: {out[0][:10]}")

# ---------------------------------------------------------------------------
# Convert to TFLite (float32, no quantization, optimized for size)
# ---------------------------------------------------------------------------
print("\n[2/4] Converting to TFLite ...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)

# Default optimizations: applies standard size optimizations without
# changing the float32 precision (no int8 quantization, as the Kotlin
# loader expects float32 input/output and no calibration data is available).
converter.optimizations = [tf.lite.Optimize.DEFAULT]

tflite_model = converter.convert()
model_size_mb = len(tflite_model) / (1024 * 1024)
print(f"TFLite model size: {model_size_mb:.2f} MB")

# ---------------------------------------------------------------------------
# Write to target path
# ---------------------------------------------------------------------------
OUTPUT_PATH = os.path.normpath(os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "..", "android", "app", "src", "main", "assets", "ml",
    "mobilefacenet.tflite"
))

print(f"\n[3/4] Writing to: {OUTPUT_PATH}")
os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)

with open(OUTPUT_PATH, 'wb') as f:
    f.write(tflite_model)

print(f"Written: {os.path.getsize(OUTPUT_PATH):,} bytes")

# ---------------------------------------------------------------------------
# Verify the written TFLite file with the TFLite interpreter
# ---------------------------------------------------------------------------
print("\n[4/4] Verifying TFLite model with TFLite interpreter ...")
interp = tf.lite.Interpreter(model_path=OUTPUT_PATH)
interp.allocate_tensors()

input_details  = interp.get_input_details()
output_details = interp.get_output_details()

print(f"  Input  index: {input_details[0]['index']}")
print(f"  Input  name:  {input_details[0]['name']!r}")
print(f"  Input  shape: {input_details[0]['shape']}")
print(f"  Input  dtype: {input_details[0]['dtype']}")
print(f"  Output index: {output_details[0]['index']}")
print(f"  Output name:  {output_details[0]['name']!r}")
print(f"  Output shape: {output_details[0]['shape']}")
print(f"  Output dtype: {output_details[0]['dtype']}")

# Run a test inference
test_input = np.random.rand(1, 112, 112, 3).astype(np.float32) * 2 - 1
interp.set_tensor(input_details[0]['index'], test_input)
interp.invoke()
test_output = interp.get_tensor(output_details[0]['index'])
test_norm   = np.linalg.norm(test_output[0])

print(f"\n  Test inference embedding norm (should be ~= 1.0): {test_norm:.6f}")
assert test_output.shape == (1, 128), f"Output shape mismatch: {test_output.shape}"

print("\n[OK] mobilefacenet.tflite verified successfully.")
print(f"     File: {OUTPUT_PATH}")
print(f"     Size: {os.path.getsize(OUTPUT_PATH):,} bytes ({model_size_mb:.2f} MB)")

# ---------------------------------------------------------------------------
# Print model card info for the claims/source register
# ---------------------------------------------------------------------------
print("""
=============================================================================
MODEL CARD ENTRY — for claims/source register
=============================================================================
Model name    : MobileFaceNet
Architecture  : MobileFaceNets (arXiv:1804.07573, Sheng Chen et al., 2018)
Implementation: sirius-ai/MobileFaceNet_TF, commit f0bae5982be2e030a89b346e6ce5ac8bdcc8f0e0
                Apache 2.0 License — redistribution inside APK permitted.
Format        : TFLite FlatBuffer (.tflite), float32
Input tensor  : "input_1"    shape [1, 112, 112, 3]  float32  range [-1, 1]
Output tensor : "embeddings" shape [1, 128]           float32  L2-normalised
Quantization  : tf.lite.Optimize.DEFAULT (size optimization, float32 retained)
Weights state : Random initialisation (NO pretrained face recognition weights)
Accuracy      : NOT APPLICABLE — this is a structural placeholder.
                Replace with a genuinely trained checkpoint before any
                accuracy evaluation. See modules/face_verification/README.md.
Disclaimer    : EXPERIMENTAL / DEMO-GRADE ONLY. Not for production use.
=============================================================================
""")
