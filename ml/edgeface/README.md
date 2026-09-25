# EdgeFace validation tools

The phone runtime is Kotlin/ONNX Runtime; Python is only a development tool.

`reference.py` generates a deterministic RGB-pattern fixture using an independent NumPy least-squares solve. Kotlin unit tests compare all 37,632 tensor components with this golden output. It is deliberately not a face or a recognition-accuracy test.

`export_model.py` accepts an official source checkout, full source commit, official checkpoint and independently recorded checkpoint hash. It verifies them, exports FP32 ONNX, checks tensor metadata and compares original PyTorch outputs with desktop ONNX. It also creates binary tensor/embedding fixtures for the explicit Android parity test. The exporter has now passed on the official S checkpoint using the locked Windows CPU environment. See `docs/edgeface-s-validation.json` for exact metrics. XS is deferred.

Example, after preparing the validated S Python environment in `requirements-export.txt`:

```text
python ml/edgeface/export_model.py --source <official-clean-checkout> --commit <full-commit> --checkpoint <official-checkpoint.pt> --checkpoint-sha256 <verified-sha256> --checkpoint-url <official-checkpoint-url> --output release-assets/edgeface
```

Download/acquisition is intentionally separate so source/checkpoint provenance is recorded before execution. Pin the official source from https://github.com/otroshi/edgeface and checkpoint URL from that revision's `hubconf.py`; retain the original notices. Check the upstream requirements against the candidate environment and record the resolved package lock after a successful export. No unverified downloaded repository is executed automatically by this script.

The generated manifest stays `redistributionStatus: pending`. Do not flip that flag until checkpoint redistribution and training-data terms have been reviewed for the intended use. Do not mark Android parity or held-out accuracy passed from the desktop report. Package no test embeddings in main assets.

For complete device steps and remaining gates, see [the implementation checklist](../../docs/edgeface-implementation-checklist.md).

Use `--model edgeface_s_gamma_05` for the S comparison and separate output directories. Both use the neutral edgeface.onnx filename; the manifest identifies the actual candidate and pins its checksum. Install only one explicitly selected, validated candidate at a time.

`prepare_phone_tests.py` stages the ignored local model/fixtures in instrumentation assets only. Run `LocalEdgeFaceModelTest` for local CPU parity; `EdgeFaceModelParityTest` remains the separate shipped-asset gate and requires production approval.
