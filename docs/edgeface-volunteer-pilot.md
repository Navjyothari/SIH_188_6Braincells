# EdgeFace-S: volunteer pilot and remaining checks

## Current decisions

- EdgeFace-S remains first; XS is deferred.
- Approximately three seconds of cold startup is acceptable to the user. Measure it separately; do not apply the two-second warm-processing target to startup.
- The warm target remains two seconds. Measure one document plus one live photo separately from one document plus three live photos.
- Full-resolution detection remains enabled. Tested detector downscales failed the fixed alignment agreement check.
- Three to five people are available voluntarily for the initial pilot.

## Stage 1 — engineering checks

Complete the sustained-use run, sampled process-memory measurements and three-live-input workload on Nord CE4. Reusing one live photo three times tests computational load only; it does not test multi-frame aggregation accuracy or independent capture variability. Record first and final 20-run batches and thermal status. PSS includes the instrumentation process and native runtime; sampled PSS is not peak camera/UI memory and does not prove absence of leaks.

Separately verify camera rotation, background/resume, retake/skip, missing-document and model/config failure handling. Existing numerical and failure tests do not establish the full manual camera lifecycle. Representative lower-end physical phones remain needed for the original hardware-class requirement.

## Stage 2 — small volunteer pilot

This is a development pilot, not held-out validation. It must not produce operational MATCH/NO_MATCH decisions or approve thresholds. Keep the main evaluation file unapproved.

For each of 3–5 consenting adults, assign an anonymous code (P01, P02, etc.). Use their own document portrait and freshly taken live photos. Explain that the images will be processed locally to test a prototype, that no real identity decision will be made, and that participation is voluntary. Do not collect their document number, address or other text for this face test. Record consent and which comparisons they permit; do not automatically use participants in cross-person comparisons without that scope being understood.

Capture one normal document photo under the intended app conditions, then three distinct straight-on live photos under ordinary light, keeping each whole face visible. The earlier close-up portrait workaround does not demonstrate reliable full-document capture. Record whether the input was a whole document, a portrait close-up, or a plain printed photo. Record glare, grayscale/security patterns and rough age-gap category when the participant is comfortable providing it. Do not request date of birth.

Capture-quality failures stay in the record even if a retake succeeds. Do not improve apparent results by dropping difficult samples. Do not intentionally collect unsafe or invasive conditions; ordinary blur, mild pose and glare can be checked through controlled retakes.

The timing diagnostic remains separate. `PilotPairEvaluationTest` records a development-only cosine, anonymous subject/pair IDs, model/preprocessing versions and quality failures; it never produces a match verdict. `ml/edgeface/pilot_session.py` starts one explicit session before capture and binds the new document/live files to that participant. Ambiguous retakes require explicit selection. Its session map and reports live under ignored `release-assets/pilot/`; no photos or raw embeddings are exported. All sessions in this pilot are development data, never held-out data.

Same-person comparisons measure genuine-pair behaviour; explicitly consented cross-person comparisons measure impostor behaviour. With 3–5 people, these are correlated observations from very few subjects: report counts, failures and exploratory score distributions, not a claimed low false-accept rate. No accuracy percentage should be produced from the current speed-only diagnostic.

## Stage 3 — threshold protocol and release gates

Use the pilot to repair capture/quality issues and define the eventual evaluation protocol. Recruit additional distinct subjects for held-out testing; pilot subjects used to make implementation choices must not be reused as independent test subjects. Freeze model, detector, alignment, quality policy, aggregation and both uncertainty-band thresholds on development data before evaluating held-out subjects. Report uncertainty and confidence intervals with repeated-subject dependence accounted for. A small volunteer set cannot certify deployment safety.

Remaining gates include official-reference alignment comparison on representative document/live images, licence applicability/redistribution evidence, held-out evaluation, approved shipped-model parity, and lower-end physical-device testing. Neither the pilot nor the sustained run satisfies those gates.

## Image lifecycle

Current capture screens leave temporary photos in app cache; prior versions also left debug crop files. Do not claim automatic deletion exists. The pilot helper provides an explicit `cleanup` action after a report exists, deleting only the two registered phone-cache photos. It does not delete unrelated files or discarded retakes; those still require separate session-specific review. Cleanup is operator-triggered, not automatic. Do not call New Screening a deletion action. Delete only clearly identified test/session files under the intended app cache or dataset directory; do not clear unrelated app data. Do not copy photos from phones or upload them as part of timing tests.


## Operator-assisted first session

Before taking photos, the assistant starts a session with a participant code such as P01 and a unique pair code such as P01-S01. Each participant must first agree to local development comparison and this temporary phone-cache retention; no cross-person consent is inferred. The helper currently automates same-person pairs only. Use one fresh document capture and one live capture per session; repeat distinct sessions if collecting further photos. Do not mix participants or start another session before the current report is saved.

```text
python ml/edgeface/pilot_session.py begin --device DEVICE --participant P01 --session P01-S01 --consent
python ml/edgeface/pilot_session.py finish --device DEVICE --participant P01 --session P01-S01
python ml/edgeface/pilot_session.py cleanup --device DEVICE --participant P01 --session P01-S01
```

`finish` runs once and retains quality failures. It refuses to guess if more than one new document/live capture exists; the operator can supply explicit new basenames with `--document`/`--live`. `cleanup` is a separate intentional action after evaluation. If future cross-person evaluation needs images to be retained, agree that scope with volunteers before collecting/retaining them; do not silently skip cleanup or reclassify consent.

For the first participant, start with the same-person single-photo flow. No extra speed repetitions are needed. Record whether this was a whole document or close-up and retain all failed attempts. The helper does not yet summarize multi-person confidence intervals or select thresholds, and its synthetic smoke test is not real-pair accuracy evidence.


### Full-document workflow correction — 2026-09-25

P03 exposed a layout issue: the main portrait plus a secondary security portrait was counted as multiple faces. Preserve that original failed attempt as a pipeline failure, not a participant/capture failure. The user requires automatic primary portrait location with the full document retained for OCR, and rejected adding a tap-selection step. That UI/selection implementation was removed before installation. The new narrow OCR-anchor locator needs device testing on the original P03 photo; no score or pass is inferred from the picture alone. Unknown multi-portrait layouts remain unsupported rather than silently selecting a face.
