"""Local-only export of an explicitly supplied official checkpoint; never downloads weights.

Outputs remain in an ignored release-assets folder until licence and evaluation gates pass.
Requires pinned official source checkout, checkpoint, and export requirements environment.
"""
import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path
import numpy as np
from reference import align_tensor, synthetic_fixture, assert_parity

def sha(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--source',type=Path,required=True)
    parser.add_argument('--checkpoint',type=Path,required=True)
    parser.add_argument('--checkpoint-sha256',required=True)
    parser.add_argument('--checkpoint-url',required=True)
    parser.add_argument('--commit',required=True)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--model',choices=['edgeface_xs_gamma_06','edgeface_s_gamma_05'],default='edgeface_s_gamma_05')
    parser.add_argument('--aligned-image',type=Path,help='Optional consented/synthetic 112x112 RGB face for parity, never an accuracy claim')
    args=parser.parse_args()
    source=args.source.resolve()
    commit=subprocess.check_output(['git','-C',str(source),'rev-parse','HEAD'],text=True).strip()
    if commit!=args.commit or sha(args.checkpoint)!=args.checkpoint_sha256:
        raise ValueError('Source/checkpoint does not match pinned provenance')
    if subprocess.check_output(['git','-C',str(source),'status','--porcelain'],text=True).strip():
        raise ValueError('Source checkout must be clean')
    import torch
    import onnx
    import onnxruntime as ort
    torch.set_num_threads(2)
    sys.path.insert(0,str(source))
    from backbones import get_model
    model=get_model(args.model)
    model.load_state_dict(torch.load(args.checkpoint,map_location='cpu',weights_only=True))
    model.eval()
    args.output.mkdir(parents=True,exist_ok=True)
    onnx_path=args.output/'edgeface.onnx'
    tensor=align_tensor(*synthetic_fixture())
    pattern=tensor.copy()
    if args.aligned_image:
        from PIL import Image
        with Image.open(args.aligned_image) as image:
            if image.size != (112,112):
                raise ValueError('Face parity image must already be aligned to 112x112')
            rgb=np.asarray(image.convert('RGB'),dtype=np.float32)
        tensor=((rgb.transpose(2,0,1)/255.0-0.5)/0.5)[None]
    torch.onnx.export(model,torch.from_numpy(tensor),str(onnx_path),
        input_names=['input'],output_names=['embedding'],opset_version=17,dynamo=False)
    onnx.checker.check_model(onnx.load(onnx_path))
    session=ort.InferenceSession(str(onnx_path),providers=['CPUExecutionProvider'])
    if session.get_inputs()[0].shape!=[1,3,112,112] or session.get_outputs()[0].shape!=[1,512]:
        raise ValueError('Unexpected model contract')
    measurements=[]
    rng=np.random.default_rng(26188)
    for value in [tensor,pattern,np.zeros_like(tensor),rng.uniform(-1,1,tensor.shape).astype(np.float32)]:
        with torch.no_grad(): expected=model(torch.from_numpy(value)).numpy()
        actual=session.run(None,{'input':value})[0]
        measurements.append(assert_parity(expected,actual))
    tensor.astype('<f4').tofile(args.output/'parity-input.f32')
    embedding=session.run(None,{'input':tensor})[0]
    embedding.astype('<f4').tofile(args.output/'parity-embedding.f32')
    manifest={
        'modelId':args.model.replace('_','-'),'modelVersion':f'{args.model}-{commit[:12]}',
        'sourceRepository':'https://github.com/otroshi/edgeface','sourceCommit':commit,
        'sourceCheckpoint':args.checkpoint_url,
        'sourceCheckpointSha256':sha(args.checkpoint),'onnxSha256':sha(onnx_path),
        'conversionCommand':sys.argv,'torchVersion':torch.__version__,'onnxVersion':onnx.__version__,
        'onnxruntimeVersion':ort.__version__,'redistributionStatus':'pending',
        'weightsLicenseStatus':'pending','trainingDataTermsStatus':'pending','codeLicense':'BSD-3-Clause',
        'alignmentVersion':'five-point-similarity-bilinear-v1',
        'input':{'name':'input','shape':[1,3,112,112],'dtype':'float32','normalization':'(rgb/255 - 0.5) / 0.5'},
        'output':{'name':'embedding','shape':[1,512],'dtype':'float32'},
        'desktopParity':measurements,
        'faceFixtureSha256':sha(args.aligned_image) if args.aligned_image else None}
    (args.output/'edgeface_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('Export and desktop numerical parity passed. Licence, Android parity and accuracy gates remain pending.')

if __name__=='__main__': main()
