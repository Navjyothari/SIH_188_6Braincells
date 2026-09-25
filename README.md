# EdgeFace offline screening branch — S first

This branch develops experimental document-portrait-to-selfie similarity for lower-end Android phones (M21-class performance across manufacturers).

**Current status:** native ONNX integration, preprocessing and fail-closed result handling are implemented. The official S checkpoint has passed desktop export and local Nord CE4 parity tests. Production licence clearance, shipped-asset parity, real-pair evaluation and thresholds are still pending. The app deliberately reports comparison unavailable until those gates pass; this is not a validated recognition release.

- [Beginner setup and phone guide](docs/edgeface-getting-started.md)
- [Setup specification](docs/edgeface-xs-offline-face-verification.md)
- [Implementation checklist, test results and manual device steps](docs/edgeface-implementation-checklist.md)
- [Model export and desktop reference tools](ml/edgeface/README.md)

The earlier MobileFaceNet experiment remains on `face-detection`. Its model and thresholds are not used by this branch. Face comparison remains optional and does not establish identity, document authenticity or liveness.
