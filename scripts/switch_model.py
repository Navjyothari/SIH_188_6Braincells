#!/usr/bin/env python3
"""
Simple script to switch between EdgeFace-S and EdgeFace-XS models.
Usage:
    python scripts/switch_model.py s
    python scripts/switch_model.py xs
"""

import sys
import shutil
import json
import hashlib
from pathlib import Path

def main():
    if len(sys.argv) < 2 or sys.argv[1].lower() not in ('s', 'xs'):
        print("Usage: python scripts/switch_model.py [s | xs]")
        print("  s  : Switch to EdgeFace-S  (Higher accuracy, 14.8 MB, 306 MFLOPs)")
        print("  xs : Switch to EdgeFace-XS (Ultra lightweight, 7.2 MB, 154 MFLOPs)")
        sys.exit(1)

    target_variant = sys.argv[1].lower()
    project_root = Path(__file__).resolve().parents[1]

    source_dir = project_root / 'release-assets' / f'edgeface-{target_variant}'
    if not source_dir.exists():
        print(f"Error: Source model folder not found at {source_dir}")
        sys.exit(1)

    # 1. Read source manifest
    source_manifest_path = source_dir / 'edgeface_manifest.json'
    source_onnx_path = source_dir / 'edgeface.onnx'

    if not source_manifest_path.exists() or not source_onnx_path.exists():
        print(f"Error: Missing model files in {source_dir}")
        sys.exit(1)

    with open(source_manifest_path, 'r', encoding='utf-8') as f:
        manifest_data = json.load(f)

    model_id = manifest_data.get('modelId')
    model_version = manifest_data.get('modelVersion')
    onnx_sha256 = manifest_data.get('onnxSha256')

    # Verify SHA256 of ONNX file
    print(f"[*] Verifying SHA-256 checksum of {source_onnx_path.name}...")
    actual_sha = hashlib.sha256(source_onnx_path.read_bytes()).hexdigest()
    if actual_sha != onnx_sha256:
        print(f"Error: Hash mismatch! Expected {onnx_sha256}, got {actual_sha}")
        sys.exit(1)
    print("    Checksum OK!")

    # 2. Copy files to android/app/src/main/assets/ml/
    target_assets_dir = project_root / 'android/app/src/main/assets/ml'
    target_assets_dir.mkdir(parents=True, exist_ok=True)

    print(f"[*] Copying {target_variant.upper()} model and manifest to app assets...")
    shutil.copy2(source_onnx_path, target_assets_dir / 'edgeface.onnx')
    shutil.copy2(source_manifest_path, target_assets_dir / 'edgeface_manifest.json')

    # 3. Update android/app/src/main/assets/ml/edgeface_evaluation.json
    eval_json_path = target_assets_dir / 'edgeface_evaluation.json'
    if eval_json_path.exists():
        print(f"[*] Updating {eval_json_path.name}...")
        with open(eval_json_path, 'r', encoding='utf-8') as f:
            eval_data = json.load(f)
        eval_data['onnxSha256'] = onnx_sha256
        with open(eval_json_path, 'w', encoding='utf-8') as f:
            json.dump(eval_data, f, indent=2)
            f.write('\n')

    # 4. Update FaceVerificationModule.kt
    module_kt_path = project_root / 'android/app/src/main/kotlin/com/sih188/borderdoc/face/FaceVerificationModule.kt'
    if module_kt_path.exists():
        print(f"[*] Updating model version in {module_kt_path.name}...")
        code = module_kt_path.read_text(encoding='utf-8')
        new_version_str = f'const val MODEL_VERSION="{model_version}"'
        import_re = False
        import re
        code = re.sub(r'const val MODEL_VERSION="[^"]+"', new_version_str, code)
        module_kt_path.write_text(code, encoding='utf-8')

    # 5. Update face_verification_result.dart default version if present
    dart_result_path = project_root / 'lib/modules/face_verification/face_verification_result.dart'
    if dart_result_path.exists():
        print(f"[*] Updating model version in {dart_result_path.name}...")
        dart_code = dart_result_path.read_text(encoding='utf-8')
        import re
        dart_code = re.sub(r"modelVersion:\s*'edgeface-[^']+'", f"modelVersion: '{model_version}'", dart_code)
        dart_result_path.write_text(dart_code, encoding='utf-8')

    print("\n" + "="*50)
    print(f"SUCCESS: Switched to EdgeFace-{target_variant.upper()} ({model_id})")
    print(f"Model File: {source_onnx_path.name} ({source_onnx_path.stat().st_size / (1024*1024):.1f} MB)")
    print(f"Model Version: {model_version}")
    print(f"SHA-256: {onnx_sha256}")
    print("="*50)
    print("\nTo build and run with the new model:")
    print("  flutter run")
    print("="*50)

if __name__ == '__main__':
    main()
