# Face verification module — EdgeFace branch

The current specification is [EdgeFace-XS offline setup](../../docs/edgeface-xs-offline-face-verification.md). Track implementation and physical-device validation in [the checklist](../../docs/edgeface-implementation-checklist.md).

This branch uses native Kotlin with ONNX Runtime CPU execution. It requires the captured document portrait and one to three selfies. It has no bundled-reference fallback, no inherited MobileFaceNet threshold, and no raw embedding/crop output to Flutter.

The checked-in model manifest and evaluation policy are pending. Until a licensed, checksum-pinned model and approved evaluation configuration exist, comparison returns NOT_RUN. The export tool and Android parity test are provided but have not established real-model performance or accuracy yet.

For the historical MobileFaceNet implementation and its documentation, inspect the `face-detection` branch.
