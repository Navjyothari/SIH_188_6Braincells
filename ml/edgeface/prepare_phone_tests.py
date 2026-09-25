"""Stage a checked local export in instrumentation assets; never writes production assets."""
import argparse
import hashlib
import json
import shutil
from pathlib import Path

def main():
    root=Path(__file__).resolve().parents[2]
    parser=argparse.ArgumentParser()
    parser.add_argument('--export',type=Path,default=root/'release-assets/edgeface-s')
    args=parser.parse_args()
    source=args.export.resolve()
    manifest=json.loads((source/'edgeface_manifest.json').read_text(encoding='utf-8'))
    model=source/'edgeface.onnx'
    if hashlib.sha256(model.read_bytes()).hexdigest()!=manifest['onnxSha256']:
        raise ValueError('Local model does not match manifest')
    for name,size in [('parity-input.f32',3*112*112*4),('parity-embedding.f32',512*4)]:
        if (source/name).stat().st_size!=size:
            raise ValueError(f'Unexpected fixture dimensions: {name}')
    assets=root/'android/app/src/androidTest/assets'
    for folder,names in {
        'ml':['edgeface.onnx','edgeface_manifest.json'],
        'edgeface':['parity-input.f32','parity-embedding.f32','synthetic-portrait.jpg'],
    }.items():
        target=assets/folder
        target.mkdir(parents=True,exist_ok=True)
        for name in names:
            shutil.copy2(source/name,target/name)
    print(f"Staged {manifest['modelId']} for local instrumentation only. Production approval stays unchanged.")

if __name__=='__main__': main()
