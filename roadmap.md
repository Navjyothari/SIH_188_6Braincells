**Build the offline Android app first, make it reliable, then add intelligence and multi-device capabilities.** Do not build the backend, dashboard, mobile app, and ML system independently and hope they integrate later.

**[ASSUMPTION]** Start date: 17 September. Initial demonstration target: 30 September. The complete research prototype will require further phases; the estimates below depend on your actual availability.

## 1. Assign six permanent owners

Names were not provided, so assign one actual person to each slot.

| Person | Primary responsibility | Owns | Backup |
|---|---|---|---|
| **P1 — Technical lead** | Rules and integration | Data contracts, document parsing, consistency checks, decision policy, release integration | P4 |
| **P2 — Mobile developer** | Offline processing | Flutter Android app, camera, Kotlin integrations, bundled OCR/model execution | P5 |
| **P3 — ML/data developer** | Experimental intelligence | Fictional dataset generator, tamper model, face-comparison experiment, artifact similarity | P1 |
| **P4 — Security/backend developer** | Reliable records | Encryption, local persistence, audit trail, later backend and synchronization | P1 |
| **P5 — UI/product developer** | User workflow | Capture guidance, evidence screens, history, later supervisor/investigator dashboard | P2 |
| **P6 — QA/evaluation lead** | Independent verification | Test fixtures, device testing, model evaluation, data permissions, documentation, releases | P3 |

**AI coding agents assist these six owners; they do not replace ownership, review, or understanding.**

## 2. Ship in this priority order

| Priority | Release | What ships | Required before moving forward |
|---|---|---|---|
| **P0** | **One complete offline screening** | Camera → OCR → supported field checks → explanation → encrypted save → reopen | Works on a freshly installed phone with all radios disabled |
| **P0** | **Usable, reliable screening app** | Capture guidance, unsupported/unreadable states, evidence crops, history, recovery | No silent failures; original evidence survives restart |
| **P0** | **Demonstration release** | Integrity verification, independent audit reference, clear limitations, backup installation | Repeatable five-minute demonstration on two phones |
| **P1** | **Evaluated intelligence** | Optional tamper analysis and consented face comparison | Each module passes independent evaluation; otherwise stays disabled |
| **P1** | **Multi-device workflow** | Backend, authenticated roles, reliable synchronization, review dashboard | Interrupted transfers do not lose or duplicate logical records |
| **P2** | **Investigator assistance** | Explainable artifact similarity, case comparison, timeline | Benign similarities are tested; results are investigative suggestions |
| **P2** | **Broader platform support** | Additional document layouts and tested second mobile platform | Each addition passes its own full workflow tests |
| **P0 before final release** | **Complete research prototype** | Security hardening, reproducible evaluation, installation, recovery, documentation | Another team member can install, operate, recover, and verify it |

**Never postpone encryption, uncertainty handling, or truthful labels until the end.**

## 3. Phase-by-phase roadmap

### Phase 1 — Build the first vertical slice

**Target: 17–19 September. Ship one working flow, using one fictional passport-style layout.**

| Person | Assigned work |
|---|---|
| **P1** | Define a shared screening-result format. Implement the first supported parser and one cross-field mismatch rule. Make government verification return `NOT_CONFIGURED`. |
| **P2** | Create Flutter Android app; integrate camera and bundled OCR; prove first-launch offline operation. |
| **P3** | Generate clean and altered fictional specimens with a fixed seed. Record expected field values and alteration locations. |
| **P4** | Implement device-protected encryption and atomic local record storage. Save original capture and result together. |
| **P5** | Build capture, processing, result, and evidence screens. Label all specimens and synthetic records visibly. |
| **P6** | Create ten independently checked fixtures. Test installation, offline capture, expected result, and restart recovery. |

**Ship gate:** Capture a fictional mismatch in airplane mode, see its explanation, close the app, reopen the same evidence.

**Cut rule:** If this fails, everyone helps fix the slice. **No CNN, face matching, clustering, or dashboard work enters the critical path.**

### Phase 2 — Make the core useful and dependable

**Target: 20–23 September. Ship the minimum usable screening app.**

| Person | Assigned work |
|---|---|
| **P1** | Complete supported structural/date/checksum rules; preserve ambiguous results; version the decision policy. |
| **P2** | Add capture guidance, rotation handling, manual crop, permission recovery, and performance instrumentation. |
| **P3** | Prepare grouped training/validation/test splits and independent-edit evaluation inputs. Begin a small tamper baseline without blocking the app. |
| **P4** | Add crash recovery, storage-error handling, canonical audit events, and chained record commitments. |
| **P5** | Add history, original-versus-extracted field comparison, recapture guidance, and recorded manual corrections. |
| **P6** | Test printed specimens under different lighting/angles; inspect false referrals, unreadable inputs, plaintext caches, and device failures. |

**Ship gate:** Twenty supported scenarios complete correctly or return an explicit recoverable failure state; completed records survive restart.

**Use four clear states:** `RECAPTURE`, `UNSUPPORTED`, `NO_INCONSISTENCY_DETECTED`, and `REVIEW_REQUIRED`.

### Phase 3 — Freeze and ship the demonstration

**Target: 24–30 September. Ship a reliable Android APK and evidence package.**

| Person | Assigned work |
|---|---|
| **P1** | Integrate and freeze the release; own the demo script and technical explanations. |
| **P2** | Fix device-specific failures; install on primary and backup phones; verify cold offline operation. |
| **P3** | Document experimental-model results and limitations. Supply reproducible examples; do not force unfinished models into the release. |
| **P4** | Implement independently retained audit checkpoints and an integrity verifier. Demonstrate alterations against a disposable copy. |
| **P5** | Polish evidence screens; prepare five slides, readable reports, and offline presentation assets. |
| **P6** | Run locked evaluation, two complete rehearsals, claim checks, release checklist, and contingency recording if permitted. |

**Ship gate:** Two phones pass the offline workflow, restart recovery works, integrity verification behaves as documented, and the demonstration finishes within five minutes.

**Freeze new features on 26 September.** Automatic synchronization, face interaction, and artifact graphics are the first cuts.

### Phase 4 — Add intelligence that earns its place

**Estimated target: weeks 3–4, after the core release.**

| Person | Assigned work |
|---|---|
| **P1** | Define how optional signals affect review; prevent missing or unreliable checks from becoming a pass. |
| **P2** | Integrate local model execution; measure memory, latency, battery impact, and desktop/mobile output consistency. |
| **P3** | Develop binary tamper analysis; evaluate a suitably licensed face model using consented test faces. |
| **P4** | Protect model versions and sensitive intermediates; implement retention/deletion behavior. |
| **P5** | Display experimental signals, source crops, unavailable states, and limitations clearly. |
| **P6** | Independently test unseen editing methods, physical recaptures, and held-out face subjects; publish raw counts and failures. |

**Ship gate:** Each optional module has documented rights, reproducible evaluation, acceptable device performance, and explicit failure handling.

**If a model fails, keep the module disabled.** A failed experiment is not a reason to weaken the evaluation.

### Phase 5 — Add backend, roles, and reliable synchronization

**Estimated target: weeks 5–6. The phone remains independently functional.**

| Person | Assigned work |
|---|---|
| **P1** | Define versioned transfer contracts, conflict behavior, and migration rules. |
| **P2** | Implement encrypted outgoing queue, retry states, reconnection handling, and visible transfer status. |
| **P3** | Package model metadata and reproducibility records for review; assist with load-test fixtures. |
| **P4** | Build FastAPI/PostgreSQL services, authentication, role authorization, idempotent uploads, and server-side audit verification. |
| **P5** | Build officer/supervisor/auditor dashboard views with permissions enforced by the backend. |
| **P6** | Test interrupted uploads, duplicate retries, conflicting payloads, unauthorized access, and recovery. |

**Ship gate:** Screening continues with the server unavailable; reconnection transfers records without silent loss or duplicate logical cases.

**Do not build administrative polish before this gate passes.**

### Phase 6 — Add investigator assistance

**Estimated target: weeks 7–8.**

| Person | Assigned work |
|---|---|
| **P1** | Define artifact-link semantics and case-review workflow. |
| **P2** | Add local comparison against records already stored on the phone. |
| **P3** | Implement one interpretable artifact-similarity method; evaluate benign same-template lookalikes. |
| **P4** | Store versioned fingerprints and review actions; enforce access and provenance. |
| **P5** | Build side-by-side case comparison first, then timeline; add a graph only if it improves inspection. |
| **P6** | Measure false links and missed planted relationships; challenge results with repeated legitimate artwork. |

**Ship gate:** Every suggested relationship shows the regions and evidence behind it.

**Call this “artifact similarity for review,” not proven fraud-ring detection.**

### Phase 7 — Expand coverage and complete the prototype

**Estimated target: weeks 9–12, subject to earlier gates.**

| Person | Assigned work |
|---|---|
| **P1** | Add supported layouts individually; maintain a capability matrix and regression suite. |
| **P2** | Implement and test a second mobile platform only when the required device/tooling is available. |
| **P3** | Evaluate each new layout and platform for model degradation; maintain model/data documentation. |
| **P4** | Harden key handling, authorization, migrations, backup/restore, retention, and audit-reference procedures. |
| **P5** | Finish administration, accessibility, reviewer workflows, installation guidance, and support screens. |
| **P6** | Run end-to-end acceptance, security regression, clean installation, recovery, and independent handoff testing. |

**Final ship gate:** Another team member can install the system from documentation, screen supported specimens offline, recover records, synchronize safely, review evidence, and verify integrity without help from the original developer.

## 4. Working rules that keep six people moving

| Rule | Implementation |
|---|---|
| **Integrate every day** | Last work hour is reserved for merging, running the phone workflow, and recording failures. |
| **Use one shared contract** | Mobile, models, storage, and dashboard consume the same versioned result schema. |
| **Keep work small** | Each task should produce a reviewable result within one or two days. |
| **Make backups operational** | Every backup runs their partner’s component at least twice a week. |
| **Protect the release** | Optional modules can be disabled without breaking core screening. |
| **Measure before expanding** | New layouts, models, and platforms require their own evidence—not inherited accuracy claims. |
| **Keep the original boundaries** | No real identity documents, fabricated government access, simulated watchlist results, or unsupported authenticity claims. |
| **Separate prototype completion from deployment approval** | A complete research prototype still requires broader validation and authorization before operational use. |