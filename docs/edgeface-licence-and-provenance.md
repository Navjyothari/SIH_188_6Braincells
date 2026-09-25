# EdgeFace-S licence and provenance findings

Checked 2026-09-24. This is an evidence record, not a statement that deployment has been approved.

## Source and checkpoint

- Official inference repository: https://github.com/otroshi/edgeface
- Pinned commit: `ce86851cfc37979a9cd2558598d0e9bc592cbba3`
- Official checkpoint included in that commit: `checkpoints/edgeface_s_gamma_05.pt`
- Immutable checkpoint URL: https://github.com/otroshi/edgeface/blob/ce86851cfc37979a9cd2558598d0e9bc592cbba3/checkpoints/edgeface_s_gamma_05.pt
- Downloaded checkpoint size: 14,695,737 bytes.
- Observed checkpoint SHA-256: `dc59abda2e8580399fd115a1eeb07e1f21156196db604b884407bcf0f17efb07`.
- This hash pins the bytes obtained from the official repository; it is not an independently published author signature.
- The separate GitLab raw checkpoint endpoint timed out. The official GitHub repository supplied the actual checkpoint; no community conversion or replacement was used.

## Code and weights are separate

The pinned GitHub root LICENSE is BSD-3-Clause. However, the publisher Idiap's official **EdgeFace-S-GAMMA model card** explicitly labels the model **CC BY-NC-SA 4.0**:

https://huggingface.co/Idiap/EdgeFace-S-GAMMA

Do not describe model weights as unrestricted BSD merely because the inference code has a BSD notice. Retain attribution and review the non-commercial/share-alike conditions before redistribution, including an ONNX conversion. The model card contains some copied Base/XS descriptions; record its model-specific licence declaration and the exact checkpoint source rather than treating all prose as independently verified.

The same card identifies WebFace260M subsets as the training source. The original dataset agreement at face-benchmark.org could not be retrieved in this session. Its terms/applicability remain pending. No claim that a hackathon or operational deployment is automatically permitted has been made.

## Current handling

The checkpoint and exported assets remain under ignored `release-assets/` for local engineering validation. Production asset approval and decision thresholds remain disabled. Desktop numerical validation is distinct from permission to redistribute, phone parity, and accuracy evaluation.
