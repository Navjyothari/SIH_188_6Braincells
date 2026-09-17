## D1 — USP set, ranked.

**Build a Flutter Android prototype that screens a supported fictional document entirely in airplane mode, explains its findings, and preserves a reviewable evidence record. Do not pitch offline processing itself as an invention.**

**Technical lead:** A narrow, reliable mobile workflow is achievable. The master document’s complete nineteen-module platform is not a credible fourteen-day commitment.

**Judge:** Commercial mobile document readers already support offline processing. Regula explicitly documents this capability; “everyone else needs the cloud” would be an immediately vulnerable claim. [Regula architecture](https://docs.regulaforensics.com/develop/doc-reader-sdk/overview/architecture/)

**Procurement reviewer:** Present a bounded research prototype with measured capabilities. “Government-ready,” “investigation-grade,” and “zero procurement” are unsupported.

| Planning fact | Treatment |
|---|---|
| Start date | **17 September 2026**, starting from scratch. |
| Demo date | **[NEEDS INPUT] [ASSUMPTION] 30 September 2026** is the planning deadline. Its meaning in the supplied table is **[needs checking]**; it does not establish the nationals demo date. |
| Capacity | **[ASSUMPTION] Six people × six focused hours/day.** Fourteen calendar days provide at most 504 gross person-hours, including review, testing, integration, and rehearsal. |
| Names and individual skills | **[NEEDS INPUT]** Not supplied. D3 assigns six distinct owner roles, M1–M6; these are placeholders for your six actual members, not invented extra staff. |
| Problem statement | Your supplied row identifies **SIH26188 / Ministry of Home Affairs [needs checking: independently unverified]**. The full official description remains unavailable. |
| Competition size | **[needs checking]** `73/500` does not establish that 500 teams are competing, or that 400 competing implementations exist. |
| Submission | Five main content slides are your stated constraint; their status as an official 2026 rule is **[needs checking]**. |

**Rank these as defensible project strengths, not claims of worldwide novelty.** No available evidence establishes what other teams have built.

| Rank | Candidate and one-sentence definition | Why a judge should care | Replication difficulty | Likely attack and decision |
|---|---|---|---|---|
| **1** | **Offline screening with reviewable evidence:** capture, explain, save, restart, and independently verify a bounded screening record without a network. | Demonstrates a complete failure-tolerant workflow and preserves why the system referred a case. | Medium–high integration difficulty; individual components are established. | “Commercial products already do this.” Acknowledge that; compete on your reproducible demonstration, explicit limitations, and evaluation. **Star.** |
| **2** | **Quality-aware abstention:** unreliable capture or unsupported input produces “recapture” or “unsupported,” rather than an invented authenticity verdict. | Reduces the chance of treating OCR failure as traveller wrongdoing. | Low–medium to implement; harder to evaluate honestly. | “That is basic product safety.” Correct. **Strong supporting behavior, weak standalone novelty.** |
| **3** | **Auditable artifact similarity:** show exactly which synthetic image regions caused two records to be suggested for review together. | Helps an investigator inspect a hypothesis without trusting an unexplained graph. | Medium for a limited demonstration; high for reliable generalization. | Shared genuine templates, printing, or camera processing can create similarity. **Conditional supporting experiment; stop calling it a fraud ring.** |
| **4** | Master USP: tamper-evident audit trail. | Makes accidental corruption and some unauthorized modifications detectable. | Low for a chain; medium for crash safety, canonical encoding, and external checkpoints. | An administrator can rewrite an unanchored chain. **Required integrity feature, not a novel technology.** |
| **5** | Master USP: offline-first, camera-only screening. | Removes connectivity from the capture-to-result dependency. | Medium integration effort; commercially established. | Offline SDKs exist; camera images cannot reveal every physical security feature. **Keep capability; kill exclusivity and “zero procurement.”** |
| **6** | Master USP: validation without a real forgery dataset. | Deterministic consistency checks remain useful when training data are scarce. | Low for checksum rules; much harder for defensible tamper detection. | Synthetic evaluation does not establish real-forgery detection. **Rename “deterministic checks plus experimental synthetic-tamper analysis.”** |
| **7** | Cross-platform, accessible app. | Makes the workflow easier to demonstrate and potentially distribute. | Low for shared UI; higher for parity across camera, model, and secure-storage implementations. | “An app is not a USP.” Correct. **Product delivery choice, not the star.** |

**Your document currently gets these things wrong:**

| Current claim or choice | Correction |
|---|---|
| “Existing products assume always-connected corridors.” | **False as a blanket statement.** Offline commercial document processing exists. |
| Fraud similarity means the same forgery kit or ring. | **Similarity is a lead, not attribution.** Show shared regions, benign lookalikes, and uncertainty. |
| A broken chain “proves post-hoc tampering.” | It establishes an integrity inconsistency under stated assumptions; corruption is another explanation. A fully rewritten chain may remain internally consistent. |
| Mobile comes after the backend, despite phone-only offline being central. | **Build the mobile vertical slice first.** A working Python backend does not establish mobile feasibility. |
| Friends’ documents provide the dataset. | **Do not collect their real identity documents.** Explicitly consented test faces are the allowed exception, on fictional cards. |
| 100–500 synthetic images justify a five-class forgery CNN. | They can test a training pipeline. They do not establish robust detection, especially when derived from a few originals. |
| “Fun” is a core officer-workflow goal. | Make it **clear, accessible, fast, and calm**. Avoid celebratory clearance animations or gamified suspicion scores. |
| “86 checkpoints, 37 centrally operated,” most volume at land borders, fragmented ownership prevents a common system. | **[needs checking]** Remove these numbers and causal claims until supported by current, directly relevant evidence. |
| “Real forged-document datasets aren’t legally obtainable.” | Remove the universal legal assertion. Your project can simply state that it uses no real forged identity documents. |

**Official-statement comparison limit:** The supplied row contains a title and metadata, not acceptance criteria. The master document’s purported quotation about an investigative digital trail is **[needs checking]**. Its land-checkpoint focus, document mix, biometrics, clustering, and offline architecture are currently **team-selected scope**, not established official requirements.

## D2 — The star differentiator.

**Pick exactly one: a complete, reviewable screening record created entirely in airplane mode.**

**Yes: your assumed star, fraud-ring clustering, is the wrong centerpiece for this deadline.**

**Judge-facing argument:** Hand the judge a phone with every radio disabled. Capture a fictional specimen whose printed date conflicts with its machine-readable text. The app shows the two values, explains the inconsistency, records which checks were unavailable, and saves the result. Force-close it, reopen it, and recover the same evidence. Then demonstrate that altering the saved record fails integrity verification against an independently retained checkpoint. None of these primitives is new; the defensible achievement is a working, inspectable chain from capture to review, including failure handling.

| Version | Exact wording |
|---|---|
| **One sentence** | “We demonstrate phone-only offline screening that preserves the evidence and limitations behind every referral.” |
| **30 seconds** | “This phone is in airplane mode, with Wi-Fi and Bluetooth off. We capture a fictional document, compare its visible and machine-readable fields, and show the exact reason for referral. The record survives an app restart, and we can check its integrity against a separately retained reference. We do not claim that a checksum proves authenticity, or that this phone consulted an issuing authority.” |
| **Single proving moment** | The reopened **Evidence** screen: original crop, extracted values, rule and model versions, reason for referral, saved-record identifier, and “Authoritative verification: NOT_CONFIGURED.” Beside it, show the independently retained checkpoint matching the record history. |

| Runner-up | Argument for it | Why it loses |
|---|---|---|
| Quality-aware abstention | Important, achievable, and easy to challenge live. | It is a necessary part of competent screening, with limited visual impact by itself. Include it inside the star workflow. |
| Artifact similarity | Visually memorable and connected to investigation. | Synthetic common artifacts can make the result nearly predetermined. Generalization, benign similarity, and attribution remain unresolved. Keep it subordinate and explicitly experimental. |

**Technical lead:** Ship the evidence screen before a graph.

**Judge:** A synthetic graph is easy to stage. Restart recovery and independent integrity verification are harder to fake convincingly.

**Procurement reviewer:** Use “screening and referral,” not “clearance,” “genuine,” or “fraud confirmed.”

## D3 — Build roadmap, day by day.

**Decision: switch the specification to Flutter, retain Kotlin for Android integrations, and ship Android first. Do not learn React Native. Do not replace the primary demo with a web-camera flow.**

Flutter supports shared application code and platform-specific integrations through channels. That supports your existing skills, but an Android Kotlin integration does not automatically supply its iOS equivalent. **Call the result “Android tested; cross-platform architecture,” until a second platform’s relevant behavior is tested.** [Flutter platform integration](https://docs.flutter.dev/platform-integration), [platform channels](https://docs.flutter.dev/platform-integration/platform-channels)

**Offline feasibility verdict: yes for the bounded local workflow; no for receiving new remote information while disconnected.** This is an architecture conclusion supported by available runtimes, not a benchmark of your unbuilt app.

| Capability | Airplane-mode feasibility | Implementation decision and boundary |
|---|---|---|
| Camera and capture guidance | Yes | Flutter camera UI; manual crop first. No gallery persistence of sensitive captures. |
| OCR | Yes | **Bundled ML Kit Latin text recognition**, packaged with the app. Avoid first-use downloads. Google documents a bundled option available immediately. [Android OCR](https://developers.google.com/ml-kit/vision/text-recognition/v2/android) |
| MRZ parsing and field comparison | Yes | Pure Dart rules; narrow supported layout. **[verified]** ICAO Doc 9303 Part 4 addresses machine-readable passports and other TD3-size documents. [ICAO scope](https://store.icao.int/en/machine-readable-travel-documents-part-4-specifications-for-machine-readable-passports-mrps-and-other-td3-size-mrtds-doc-9303-4) |
| Small tamper model | Technically yes; usefulness unproven | Bundle a small exported ONNX model; run on CPU initially. Mobile runtime support does not establish detection accuracy. [ONNX Runtime mobile](https://onnxruntime.ai/docs/tutorials/mobile/) |
| Face comparison | Technically yes; optional | Requires a separate licensed embedding model and alignment pipeline. ML Kit face detection does **not** recognize people. [ML Kit face detection](https://developers.google.com/ml-kit/vision/face-detection) |
| Encrypted local record | Yes | Encrypt before persistent writes; protect the device key with Android Keystore. [Android Keystore](https://developer.android.com/privacy-and-security/keystore) |
| Local artifact comparison | Yes | Compare only records already on that phone. Mark imported examples and their provenance. |
| Cross-checkpoint updates | **No while fully disconnected** | Historical imported data can be inspected; new remote cases arrive only after a transfer or reconnection. |
| Government verification | Excluded | Always `NOT_CONFIGURED`; no requests, simulated replies, or fabricated watchlist hits. |
| Training and installation | Outside the runtime claim | Train and package before the demo. The released installation must contain everything needed for first launch offline. |

**Do not use the ML Kit document-scanner component as an unnoticed first-run dependency.** Google lists text recognition as bundle-capable but its document scanner as unbundled. [Model installation paths](https://developers.google.com/ml-kit/tips/installation-paths)

**Acceptance target [ASSUMPTION]:** a fresh installation starts offline, handles twenty sequential supported captures without a crash, and achieves a measured capture-to-result p95 of at most ten seconds on each of two named test phones. These are project gates, not claimed results.

| Owner | One actual team member fills this role | Backup |
|---|---|---|
| **M1 — Lead/rules** | Integration, parsing, decision states, technical narration | M4 |
| **M2 — Mobile** | Flutter shell, camera, Kotlin OCR/runtime bridge | M5 |
| **M3 — ML/data** | Synthetic generator, model experiment, model packaging | M1 |
| **M4 — Security/storage** | Encryption, persistence, audit verification, optional transfer | M1 |
| **M5 — Experience/review** | Evidence screens, accessible UI, read-only web report, slide visuals | M2 |
| **M6 — QA/claims** | Independent fixtures, evaluation, provenance, documentation, rehearsal | M3 |

**[NEEDS INPUT] These owner IDs must be mapped to your six names.** No named roster was supplied, so assigning real names would be fabrication.

Each cell below states **work → binary done test**. All dates are September 2026. “Done” requires a working integrated artifact, not a branch or screenshot.

| Day | M1 + M2: mobile/rules track | M3 + M6: data/evaluation track | M4 + M5: evidence/product track | Dependency unblocked |
|---|---|---|---|---|
| **17** | M1 defines result contract and a rule fixture → fixture passes. M2 installs Flutter camera/OCR build → one capture produces text offline. | M3 creates fictional template generator → seed reproduces output. M6 writes scope/provenance and test manifest → every fixture has an owner and source. | M4 encrypts a synthetic payload → survives restart and decrypts. M5 builds evidence shell → every state visibly says TEST DATA. | Shared contract and first phone execution. |
| **18** | M1 parses supported fields/checks → expected result for each fixture. M2 connects camera to rules → captured mismatch reaches Evidence screen offline. | M3 locks root/template split → overlap check passes. M6 supplies ten independently checked cases → all expected states recorded. | M4 saves original/result atomically → forced restart loses no completed record. M5 binds real result data → no hardcoded verdicts. | **First integrated vertical slice.** |
| **19 — Gate 1** | M1 adds unreadable/unsupported states → no failure defaults to pass. M2 fresh-installs with radios off → first capture works without download. | M3 generates train/validation data → manifests reproducible. M6 runs twenty core scenarios → report distinguishes capture failures and wrong results. | M4 checks plaintext/temp leakage → no unencrypted app-created capture remains. M5 completes recapture guidance → tester can recover unaided. | Proves phone-only architecture early. |
| **20** | M1 adds date ambiguity and correction provenance → ambiguous date abstains. M2 handles rotation/permissions → recoverable errors shown. | M3 trains binary baseline → model and training manifest saved. M6 assembles independent validation edits → separated from training generator. | M4 implements canonical audit events → same bytes give same digest. M5 builds history → recovered record opens correct evidence. | Reliable core plus experimental baseline. |
| **21** | M1 versions decision policy → record retains policy version. M2 loads model through native bridge → test tensor runs on phone. | M3 checks desktop/mobile parity → agreed tolerance passes. M6 begins controlled physical-photo set → capture conditions logged. | M4 links records transactionally → crash tests preserve valid prefix. M5 builds audit view → modification yields visible failure. | **Integration day 2:** optional inference plus integrity. |
| **22** | M1 adds optional-check states → absent model is `NOT_RUN`. M2 profiles two phones → latency and memory report exists. | M3 audits embedding model license and local inference → lawful-use basis and runtime verified, or face branch closed. M6 prepares consented-subject protocol → consent precedes capture. | M4 exports non-sensitive audit checkpoint → separately retained reference verifies. M5 adds side-by-side crops → provenance visible. | Independent integrity reference; face go/no-go evidence. |
| **23 — Gate 2** | M1/M2 integrate only passing optional modules → disabling either leaves core functional. | M3 freezes candidate model/threshold. M6 runs independent validation → thresholds below pass or module is disabled. | M4 tests mutation, reordering, deletion and truncation against saved checkpoint → every expected outcome correct. M5 labels experimental outputs → no authenticity probabilities. | Locks feature scope before final test. |
| **24** | M1 completes unsupported-input rules → unsupported layout never receives a normal result. M2 fixes blocking defects → core regression passes. | M3 implements small local artifact comparison → returns ranked pairs with crops. M6 tests same-template benign decoys → false links counted. | M4 implements synthetic-only report export → no face images or embeddings included. M5 opens report on phone and laptop browser → same record/version shown. | Cross-platform review, not untested cross-platform inference. |
| **25** | M1 reviews final error categories → each failure has a truthful UI state. M2 runs sustained session → no unresolved crash. | M3 hands frozen model to M6. M6 runs locked test set once → signed-off raw results and denominators saved. | M4 tests full-disk/key-loss behavior → no silent data loss or pass. M5 drafts five slides → every metric links to evidence. | **Integration day 3:** measured release candidate. |
| **26 — Gate 3** | M1 freezes scope/build → checklist signed. M2 installs candidate on backup phone → offline core passes there too. | M3 documents failures → model card matches evidence. M6 performs two full rehearsals → each finishes within five minutes. | M4 verifies export/checkpoint recovery → independent verifier passes. M5 freezes accessible layouts → no clipped critical text. | Release freeze and concrete cuts. |
| **27** | M1 answers adversarial Q&A → no unsupported claims. M2 fixes only critical defects → targeted regressions pass. | M3 prepares failure-case examples → labels correct. M6 records offline and restart evidence → build identifier visible. | M4 rehearses tamper demonstration on a copy → primary dataset unaffected. M5 captures permitted contingency clips → timestamp and build shown. | Rehearsable demonstration and backup evidence. |
| **28** | M1 runs handoff exercise → backup can explain rules. M2 prepares signed APK/install instructions → another member installs successfully. | M3 packages reproducibility assets → clean regeneration succeeds. M6 audits claims/licensing → no unresolved asset in release. | M4 prepares reset/backup procedure → restored synthetic state verifies. M5 finalizes five slides and report → opens offline. | **Integration day 4:** release rehearsal from clean setup. |
| **29** | M1 freezes release identifier → slides/video/app agree. M2 charges devices and checks projection → local display works. | M3 verifies model checksums → match release manifest. M6 performs final smoke test → checklist passes without tuning. | M4 duplicates recovery assets → second copy opens. M5 rehearses transitions → under five minutes. | Demo readiness; no feature work. |
| **30 [ASSUMPTION]** | M1 presents; M2 operates → script completes. | M3 answers model questions; M6 times and logs failures → truthful result record retained. | M4 handles audit/recovery; M5 operates slides/video → correct contingency selected if needed. | Demo and submission. |

**Three hard cut-lines:**

| Gate | Required evidence | If it fails |
|---|---|---|
| **19 September: phone core** | Fresh installation, radios off, camera → OCR → rule → encrypted record → reopen. | **Drop CNN, face, clustering, and web report work temporarily.** M2 builds the same core directly in Kotlin if the Flutter bridge is the blocker; M5 supports the UI. Do not substitute laptop inference and keep claiming phone-only operation. |
| **23 September: optional intelligence** | CNN: on independent validation, sensitivity ≥70% at false-referral rate ≤10%, using at least 100 clean and 100 manipulated validation examples. Face: license cleared, local execution works, threshold fixed on development subjects, no hidden downloads. These are **[ASSUMPTION] demo gates**, not production thresholds. | **Drop the failing optional module from decisions.** Retain its limitations report; show `NOT_RUN`. No fake scores, manually chosen verdicts, or server fallback disguised as local inference. |
| **26 September: reliability** | Two phones pass core offline flow; record survives restart; audit reference verifies; two five-minute rehearsals succeed. | **Drop artifact grouping, automatic sync, secondary-platform work, and optional live face interaction.** Ship core Android evidence workflow plus explicit manual export. |

## D4 — Do's and Don'ts.

**Technical**

| Rule | Reason | Consequence of breaking it |
|---|---|---|
| **Bundle every runtime model and asset.** | Installed SDK code can still depend on downloaded models. | First airplane-mode launch fails. |
| Preserve original capture separately from processed images. | Processing can change apparent forensic signals. | You cannot explain whether an artifact came from the document or your own pipeline. |
| Use `RECAPTURE`, `UNSUPPORTED`, `NO_INCONSISTENCY_DETECTED`, and `REVIEW_REQUIRED`. | Input quality and supported scope must precede interpretation. | Bad OCR becomes a false accusation. |
| Record manual corrections separately from original OCR. | A corrected field is human input. | Claimed OCR accuracy and evidence provenance become misleading. |
| **Keep experimental CNN scores outside the core decision until validated.** | Raw scores are not calibrated fraud probabilities. | Arbitrary thresholds appear authoritative. |
| Encrypt before writing originals, thumbnails, or sensitive intermediate files. | Encrypting only the final database leaves copies behind. | The advertised storage protection is incomplete. |
| Use per-record identifiers and transactional writes. | Crashes can otherwise separate results, images, and audit events. | History becomes inconsistent. |
| Verify against an independently retained chain head and sequence count. | Internal consistency does not detect every rewrite or truncation. | “Tamper-proof audit” is punctured immediately. |

**Legal, ethical, and claims**

| Rule | Reason | Consequence of breaking it |
|---|---|---|
| **No friends’ real identity documents.** | This violates your stated ground rule even if they agree. | The dataset and demo breach your own specification. |
| Consented face testing requires separate permission for capture, processing, display, and recording. | Permission for one use does not establish permission for every use. | Volunteers may be exposed beyond their understanding. |
| Government interface stays `NOT_CONFIGURED`, including in demos. | There is no authorized connection. | Simulated government evidence misleads judges. |
| Say “supported structural and consistency checks.” | **[verified]** ICAO Doc 9303’s travel-document scope is distinct from the separate Aadhaar offline-verification mechanisms documented by UIDAI. [ICAO](https://store.icao.int/en/machine-readable-travel-documents-part-4-specifications-for-machine-readable-passports-mrps-and-other-td3-size-mrtds-doc-9303-4), [UIDAI](https://uidai.gov.in/en/921-faqs/aadhaar-online) | A blanket compliance claim is indefensible. |
| Do not claim implemented Aadhaar signature verification. | **[verified]** UIDAI describes digitally signed offline artifacts, but your implementation has not verified them. **Aadhaar support is excluded from this build.** [UIDAI offline verification](https://uidai.gov.in/en/921-faqs/aadhaar-online) | Describing a standard becomes a false product claim. |
| **ELA is a signal; checksum success is consistency, not authenticity.** | Neither establishes that an issuer produced the document. | Your central conclusion exceeds the evidence. |
| Every record, crop, report, chart, and export carries specimen/synthetic status. | Labels must survive navigation and export. | Demonstration data may be mistaken for operational records. |
| Treat code, model weights, and source data as separate licensing questions. | A permissive wrapper does not license everything it loads. | You may demonstrate or distribute an asset without suitable rights. |
| Remove unsupported institutional statistics. | Checkpoint counts, ownership, and throughput claims are **[needs checking]**. | A factual challenge undermines the pitch. |

**Demo-day**

| Rule | Reason | Consequence of breaking it |
|---|---|---|
| Show airplane mode **and Wi-Fi/Bluetooth off**. | Radios can be manually re-enabled while airplane mode remains shown. | Your proof is ambiguous. |
| Let the judge select between prepared, labelled specimens. | Demonstrates actual input dependence. | A fixed result looks scripted. |
| Run the tamper demonstration against a disposable copy. | Keep your main demo history intact. | The remaining demonstration may fail. |
| **Never describe imported images as a live capture.** | Processing and acquisition are different capabilities. | Fallback becomes deception. |
| Use text/icons as well as color; large controls and clear retake guidance. | Errors should be recoverable and visible. | Interface polish hides usability failures. |
| No “traveller cleared” animations. | This prototype supplies screening evidence. | The UI claims authority the system does not have. |

**Submission and documentation**

| Rule | Reason | Consequence of breaking it |
|---|---|---|
| Keep one claim-to-evidence register. | Slides, app, README, and narration must agree. | Judges find contradictory capability claims. |
| Mark planned, implemented, tested, and excluded separately. | Architecture diagrams are not demonstrations. | Roadmap features look falsely complete. |
| Pin versions and record asset hashes. | Evaluation depends on a particular build. | Results cannot be reproduced. |
| Record exact dataset denominators and grouping. | Augmented images are not independent documents. | Reported accuracy is inflated. |
| Check the actual 2026 template and AI-assistance rules. | Their current terms remain **[needs checking]**. | An otherwise strong submission may violate format or process. |
| Document what each person understands and owns. | AI-assisted code still requires human accountability. | The team cannot answer implementation questions. |

## D5 — Risk register.

**[ASSUMPTION] Likelihood and impact use a 1–5 planning scale. These are prioritization judgments, not measured probabilities.**

| Rank | Risk | L × I | Early warning | Mitigation | Concrete fallback |
|---|---|---:|---|---|---|
| 1 | Scope exceeds available time | 5 × 5 = **25** | No phone vertical slice after day two | M1 enforces one layout and hard gates | Core OCR/consistency/evidence app only |
| 2 | OCR fails on photographed specimens | 4 × 5 = **20** | Digital renders work; printed, angled captures fail | M2 adds guidance; M6 tests physical captures early | Guided MRZ crop and explicit recapture; manual correction recorded separately |
| 3 | “Offline” hides download or service dependency | 4 × 5 = **20** | Warm device works; fresh installation fails | M2 tests cold offline installation by day three | Remove dependency or module; keep fully local rules |
| 4 | CNN learns generator fingerprints | 5 × 4 = **20** | High same-generator accuracy, poor independent-edit results | M3 uses grouped splits and nuisance matching; M6 supplies unseen editing method | Disable CNN contribution; publish failed generalization result |
| 5 | Exam absence removes critical owner | 4 × 4 = **16** | Long-lived branch, no handoff, only one working machine | Backups review and run partner’s code daily | Freeze absent owner’s optional feature; backup maintains core |
| 6 | Unsupported PS/rule/claim assumptions | 3 × 5 = **15** | Deadline, format, or required scope inferred from metadata | M6 obtains official text and maintains traceability | Mark unverified claims; submit bounded capabilities without invented compliance |
| 7 | Face threshold misrepresents reliability | 4 × 3 = **12** | Threshold tuned on demo subjects; near-zero test diversity | Subject-disjoint development/test; uncertain band; no liveness claim | Drop numerical matching; optional human comparison of consented test portraits |
| 8 | Queue/transfer loses or duplicates records | 3 × 4 = **12** | Retry creates duplicates; interrupted write disappears | M4 tests kill/retry, unique IDs, digest conflicts | **Drop automatic sync**; verified manual export |
| 9 | Device, projection, power, or network fails | 3 × 4 = **12** | Only one phone; wireless projection; uncached slides | Second phone, local slides, tested wired projection, power bank | Continue on backup phone; labelled recording only if permitted |
| 10 | Sensitive data or key handling leaks information | 3 × 4 = **12** | Images appear in gallery/logs; keys in repository | M4 inspects persistence; M6 audits release contents | Synthetic-only demo; disable face capture and remove sensitive export path |

## D6 — Judge Q&A prep.

**Answers describe the proposed final behavior. Where a result is not measured, say so; never memorize a placeholder as a fact.**

| # | Hard question | Tight answer |
|---|---|---|
| **1** | **“How do you know your tamper model isn’t just detecting your own synthetic generator?”** | **Judge:** We do not infer generalization from a random split of generated images. We separate base documents and template families, balance processing artifacts across labels, and test independently edited, physically recaptured specimens. If that test fails, the CNN is disabled in screening and reported as an unsuccessful experiment. |
| **2** | **“What’s your false-positive rate and what happens to a real traveller when you’re wrong?”** | **Procurement reviewer:** We report the observed false-referral count and denominator on a defined fictional-specimen test set; a traveller-population rate is not established. The prototype never authorizes rejection or clearance and separates recapture from suspicious inconsistency. Any operational use would need an approved human-review process and much broader validation. |
| **3** | **“Your hash chain is centralised—who stops the admin rewriting it?”** | **Technical lead:** A local chain alone does not stop that administrator. We compare it with a previously retained head and sequence count outside the mutable store, which can expose a conflicting rewrite of that prefix. An attacker controlling both records and references, or fabricating data before anchoring, remains outside that guarantee. |
| **4** | **“Why not just use the existing e-gate vendor?”** | **Procurement reviewer:** Buying an established product may be the right decision. Our prototype does not establish superiority over commercial readers or e-gates, and offline document SDKs already exist. We offer a bounded workflow and evaluation harness that can help compare cost, integration, explainability, and local operation. [Commercial offline capability](https://docs.regulaforensics.com/develop/doc-reader-sdk/overview/architecture/) |
| **5** | **“How is this different from the other 400 teams doing OCR plus a CNN?”** | **Judge:** We have not inspected those teams, so we cannot substantiate the number or their implementations **[needs checking]**. Our demonstrable contribution is a complete offline workflow with abstention, restart recovery, versioned evidence, and independently checkable integrity. We invite you to test those behaviors directly. |
| **6** | “Does offline mean the phone works alone, or is a laptop secretly doing inference?” | **Technical lead:** The core pipeline runs on the phone with all radios disabled. We test first launch after a fresh installation, not merely a device with previously cached downloads. The laptop displays slides or verifies exported evidence; it performs no hidden screening computation. |
| **7** | “Can it detect a well-made counterfeit with correct text?” | **Judge:** Not reliably from our current evidence. Matching text and checksums can coexist with a counterfeit, and a standard photograph does not expose every relevant physical feature. Our output is a bounded screening result, with unsupported authenticity questions left unresolved. |
| **8** | “Why should matching stamps mean coordinated fraud?” | **Judge:** It should not. Our optional view suggests similar regions for inspection and includes genuine-looking template similarities as negative controls. It does not identify a criminal organization, common manufacturer, or shared intent. |
| **9** | “You said cross-platform; where is the iPhone version?” | **Technical lead:** The tested screening target is Android. Shared Flutter code and a browser report do not prove iOS camera, model, or secure-storage parity. We label other platforms as planned until the complete relevant workflow passes on them. |
| **10** | “Where did your data come from, and did your friends give you passports?” | **Procurement reviewer:** We do not collect friends’ real identity documents. The document dataset uses original fictional templates and controlled synthetic alterations with recorded provenance. Consenting adults may provide test face images under a separate protocol, and those images stay out of the public repository. |
| **11** | “What does a model score of 0.87 actually mean?” | **Judge:** It is a model output under our experimental setup, not an 87% chance of fraud. Unless calibration is demonstrated on an appropriate population, we label it an experimental score. We primarily show observable inconsistencies and the conditions under which a check was run. |
| **12** | “What prevents a printed face or replayed video from passing?” | **Technical lead:** We make no presentation-attack resistance claim. Face similarity alone does not establish live presence, and a blink demonstration would not settle that problem. This build excludes operational liveness and treats face comparison as optional experimental evidence. |
| **13** | “What happens when OCR reads a date incorrectly?” | **Technical lead:** Poor-quality or ambiguous extraction produces recapture or review rather than a forgery assertion. The officer can inspect the original crop and correct a field, but the correction is recorded separately. Our evaluation also counts acquisition and extraction failures instead of hiding them. |
| **14** | “Aren’t checksums enough to validate a passport?” | **Judge:** A checksum is a consistency check, not evidence that an issuer created the document. **[verified]** ICAO Doc 9303 includes specifications for machine-readable travel documents; our implementation claims only its tested subset. We do not turn a passing check into an authenticity certificate. [ICAO scope](https://store.icao.int/en/machine-readable-travel-documents-part-4-specifications-for-machine-readable-passports-mrps-and-other-td3-size-mrtds-doc-9303-4) |
| **15** | “Are you connected to immigration or identity databases?” | **Procurement reviewer:** No. Every government-verification interface returns `NOT_CONFIGURED`, and no demo uses fabricated government responses. The local workflow operates independently of those services. |
| **16** | “What happens if the phone is stolen or an administrator has root access?” | **Technical lead:** Encrypted storage and a device-protected key reduce exposure from some storage-access attacks. They do not make an unlocked or compromised endpoint trustworthy. We document that boundary and do not claim protection against a fully compromised operating system. |
| **17** | “How do you synchronize without duplicates?” | **Technical lead:** If automatic transfer is included, a stable record ID plus digest makes retries idempotent and conflicting payloads visible. An interrupted upload remains pending until a verified acknowledgement. If those tests do not pass, the released prototype uses explicit manual export and makes no automatic-sync claim. |
| **18** | “How did fifteen friends establish a safe face threshold?” | **Judge:** They did not establish an operationally safe threshold. At most, a subject-separated pilot demonstrates that a specific comparison pipeline runs and exposes some failure modes. We report the number of people and sessions, and do not treat thousands of correlated pair comparisons as thousands of independent people. |
| **19** | “Are you allowed to deploy the pretrained face model commercially?” | **Procurement reviewer:** The answer depends on the exact weights and license, not the wrapper library. InsightFace distinguishes permissive code licensing from restrictions on supplied pretrained models. We either document permission suitable for this demonstration or exclude those weights; procurement rights remain a separate requirement. [InsightFace licensing](https://github.com/deepinsight/insightface/blob/master/README.md) |
| **20** | “What remains before an actual government deployment?” | **Procurement reviewer:** We have not established operational acceptance, population-level error rates, integration authorization, or deployment compliance. A future evaluation would need representative data, security assessment, device management, retention decisions, and an approved human-review procedure. This submission demonstrates a research prototype and its measured limits. |

## D7 — Demo script.

**Five minutes. M1 narrates; M2 operates the phone; M4 handles integrity; M5 handles slides; M6 times and controls contingency playback. M3 answers ML questions afterward.**

**[ASSUMPTION] Five-minute slot. The actual 2026 allowance and recording policy are [needs checking].**

| Time | Speaker/operator | On screen | Exact sentence(s) | Failure fallback |
|---|---|---|---|---|
| **0:00–0:20** | M1 / M5 | One-line scope; TEST DATA label | “We built a phone-only screening prototype that preserves the evidence behind a referral. Every document shown today is fictional test data.” | If slides fail, M1 says the same line with the app’s labelled home screen visible. |
| **0:20–0:40** | M1 / M2 | System radio settings, then app launch | “Airplane mode is on, Wi-Fi and Bluetooth are off, and the screening pipeline runs on this phone.” | If projection fails, show the physical phone to judges. Do not enable wireless mirroring and retain the same claim. |
| **0:40–1:10** | M1 / M2 | Deliberately poor capture → recapture guidance | “This capture is unreadable, so the system requests another image; it does not accuse the document holder.” | If the chosen bad image passes, say: “This quality check missed the problem; we count that as a failure.” Move to a controlled labelled quality fixture. |
| **1:10–1:40** | M1 / M2 | Clean fictional specimen → evidence | “The supported checks found no inconsistency in this specimen. That result does not establish that a document is genuine.” | Import the same labelled image: “Camera capture failed; we are now demonstrating local processing of an imported test image.” |
| **1:40–2:20** | M1 / M2 | Altered fictional specimen; conflicting values and original crops | “These two extracted dates disagree, and you can inspect the source regions yourself. That observable conflict is the reason for referral.” | If OCR fails, show the failure state; open a previously captured record labelled “earlier test capture.” Never silently replace OCR output. |
| **2:20–2:45** | M1 / M2 | Model status or optional experimental result | If enabled: “This additional score comes from an experimental synthetic-tamper model; it is not a probability of fraud.” If disabled: “Our independent test did not justify using the tamper model, so screening proceeds without it.” | Show `NOT_RUN` and continue. No prerecorded score is presented as live. |
| **2:45–3:15** | M1 / M2 | Force-close, reopen, recovered evidence record | “After restarting the app, the original evidence, result, and version information are still available.” | Switch to backup phone and say: “Recovery failed on the primary device; this is our backup installation.” |
| **3:15–3:55** | M4 | Independent saved checkpoint; disposable altered record → failed verification | “This retained reference lets us detect that the saved history no longer matches. A hash chain alone would not stop an administrator rewriting the entire history and its reference.” | Show the recorded integrity test, explicitly labelled, if recordings are permitted. Otherwise explain the failed step and show the saved test report. |
| **3:55–4:20** | M1 / M2 | Optional artifact pair with highlighted crops, or limitations screen | If included: “These synthetic cases share a similar region; that suggests a comparison for review, not a proven fraud ring.” If cut: “We excluded artifact grouping because we could not separate useful links from benign similarities reliably.” | Use the limitations screen. Do not show a decorative graph as computed evidence. |
| **4:20–4:40** | M1 / M2 | Capabilities panel | “Authoritative verification is not configured. Unsupported documents and checks remain visibly unsupported.” | Use the static capability manifest marked as documentation. |
| **4:40–5:00** | M1 / M5 | Measured results with denominators and limitations | “Our claims are limited to this tested build, these devices, and the stated specimen set. The deliverable is an inspectable offline workflow that an officer could evaluate further.” | Read the tested scope from the app’s About screen; omit any unavailable metric. |

**Prerecorded-video contingency policy:** Record the actual release build, with date, build identifier, input labels, and radio state visible. M6 may switch after one failed retry or roughly ten seconds of obstruction; announce **“This is a recording of an earlier test, not the current live result.”** Do not splice away failures while implying an uninterrupted run. If recordings are prohibited **[needs checking]**, use the backup phone and static test evidence.

## D8 — Data strategy.

**Use friends as consenting usability/face-test participants, not as a source of identity documents. Ten to fifteen people are enough for an integration pilot, not a population-level biometric claim.**

| Data category | Source and permitted project use | Target [ASSUMPTION] | Compliance vulnerability |
|---|---|---:|---|
| Fictional documents | Team-created layouts, fictional fields, original symbols, permanent SPECIMEN markings | 12 layout families × 100 fictional root documents | Avoid reproducing official seals or creating documents presented as usable credentials. |
| Tampered examples | Controlled edits to those fictional roots only | Two altered derivatives per root | Model might learn editing artifacts instead of tampering. |
| Clean controls | Untampered roots processed through equivalent export and capture pipelines | Two benign derivatives per root | If clean samples skip processing used on tampered samples, the experiment is confounded. |
| Physical camera captures | Print and photograph approved fictional specimens under logged conditions | 240 test photos from 80 roots; three conditions each | Repeated captures are correlated and must not inflate independent sample counts. |
| Independent edits | M6 manually edits permitted fictional roots with a different method/tool from M3’s generator | Separate validation and final-test subsets | Merely using another random seed is not independent editing. |
| Face images | Explicitly consenting adult volunteers; fresh portraits attached to fictional test cards | 10–15 people; multiple sessions | Small, convenience sample; no real identity documents; separate display/recording consent. |
| Public specimens | Only sources with documented permission covering the exact copying, alteration, training, and redistribution uses | Optional; **zero required** | “Publicly viewable” is not a sufficient reuse license. |
| Pretrained models | Identified release, checksum, weight license, and permitted purpose | One small candidate per optional task | Model permissions may differ from code permissions. |

**Do not scrape PRADO into the training set.** Its publisher sets specific restrictions on copying and reuse; treat permission for your intended use as unresolved unless established. Using your own fictional artwork avoids this dependency. [Council copyright notice](https://www.consilium.europa.eu/en/about-site/copyright/)

**How many CNN samples are enough?** There is no defensible universal number. **100–500 images are a pipeline smoke test.** A proposed 4,800-image controlled experiment can reveal some failure modes; it still cannot establish performance on real forged documents.

| Step | Reproducible recipe |
|---|---|
| **1. Seed and environment** | Fix `seed = 26188`; seed Python, NumPy, and the training framework. Record dependencies, generator commit, fonts, renderer, and asset hashes. Record nondeterministic training operations rather than promising bit-identical GPU results. |
| **2. Split before generation** | Allocate eight layout families to training, two to validation, two to test. That yields 800/200/200 roots before derivatives. Keep every derivative, crop, and physical recapture of a root in the same split. |
| **3. Protect assets across splits** | Separate fictional identities, portraits, stamp artwork, and source patches. Hold out additional nuisance settings and at least one editing implementation for challenge tests. |
| **4. Generate clean controls** | Produce two benign views per root using randomized compression, rescaling, mild blur, illumination, and perspective variation. Retain legitimate-looking same-template and repeated-logo examples. |
| **5. Generate manipulated examples** | Produce two altered views per root, distributing portrait replacement, text replacement, fictional-stamp alteration, and copy/paste operations across the dataset. Store edit masks and operation parameters as ground truth, never as model inputs. |
| **6. Match nuisances** | Both labels go through the same pools of encoders, compression ranges, image sizes, filenames, metadata removal, and watermark placement. Include clean “open and re-save” controls. |
| **7. Preserve labels** | Use `UNTAMPERED_SYNTHETIC` and `ALTERED_SYNTHETIC`, not “genuine” and “forged.” Every displayed derivative remains visibly labelled. |
| **8. Train narrow model** | Start with binary altered/untampered classification using a small mobile-suitable backbone. Record alteration subtype for analysis, without committing to a five-class UI. |
| **9. Challenge the shortcut** | Evaluate on independently edited images, phone photographs, unseen layouts, and benign compression changes. Compare results with and without non-content margins to detect watermark/background dependence. |
| **10. Freeze and test** | Tune only on validation data. M6 holds the final-test manifest; freeze threshold and model before opening results. A failed final test leads to limitation disclosure or module removal, not hidden retuning on the same set. |

The proposed generated total is **1,200 roots × four derivatives = 4,800 images**: 3,200 training, 800 validation, and 800 test. **Report 1,200 roots and twelve layout families too**; image count alone exaggerates diversity.

**Face split [ASSUMPTION]:** With fifteen adults, allocate five to development and ten to the held-out pilot; with ten, allocate four and six. Keep people disjoint across threshold selection and final evaluation. Do not train a face embedding model on this sample.

**Procurement reviewer:** Written consent is a project safeguard, not a claim of comprehensive legal compliance. Use a stated deletion date, separate identity-to-subject mapping, encrypted storage, and a withdrawal process; institutional requirements remain **[NEEDS INPUT]**.

## D9 — Metrics we can honestly report.

**Every number below is a measurement plan or phrasing template. No performance results exist yet.**

| Metric | How and on what set | Honest reporting phrase | If weak |
|---|---|---|---|
| OCR exact-field accuracy | Compare original OCR with human-checked ground truth on physical test captures; report by field | “On `[N]` fictional-document captures from `[R]` roots, `[x/N]` target fields were extracted exactly.” | “Results degraded under `[condition]`; the app requests recapture.” |
| End-to-end supported-check success | Correct capture → extraction → rule outcome across all attempted supported cases | “The complete pipeline produced the expected state in `[x/N]` attempts, including failed captures in the denominator.” | Narrow the supported capture envelope. |
| Parser/rule correctness | Independently constructed checksum, date, malformed-input, and cross-field fixtures | “The implementation passed `[x/N]` specified rule fixtures; this measures rule behavior, not document authenticity.” | Do not ship a known incorrect critical rule. |
| Quality-gate effectiveness | Controlled acceptable/poor captures; log false rejects and false accepts | “The gate rejected `[x/y]` deliberately poor captures and incorrectly rejected `[a/b]` acceptable captures.” | Describe the quality gate as limited; increase explicit user inspection. |
| False referral and missed inconsistency | Separate untampered synthetic controls and altered cases; count abstentions separately | “At frozen policy version `[v]`, `[a/b]` clean specimens were referred and `[c/d]` altered specimens were missed.” | Disable the unreliable contributor; report the pre-change result transparently. |
| CNN generalization | Same-generator versus independent-editor/physical-photo tests | “Performance changed from `[A]` to `[B]` under independent editing; these are synthetic-domain results.” | “The model did not generalize sufficiently and is excluded from screening decisions.” |
| Face FMR/FNMR and acquisition failures | Fixed threshold, held-out people, logged sessions; record people as well as pair counts | “In a pilot of `[n]` consenting adults, we observed `[counts]`; operational biometric error rates remain unestablished.” | Disable pass/fail matching; keep no numeric claim. |
| Artifact-link precision/recall | Synthetic known shared artifacts plus benign same-template decoys; pair and cluster counts | “Within this labelled scenario, `[x/y]` suggested links matched the planted artifact relationship.” | Remove clustering from the live demonstration. |
| Offline latency/reliability | Fresh install, radios off, two named phones, cold/warm runs, repeated session | “On `[device/build]`, p50/p95 processing time was `[x/y]`, with `[c/N]` completed attempts.” | State the slower device/conditions; remove slow optional modules. |
| Persistence/integrity | Crash, write interruption, mutation, deletion, reorder, rewritten-chain and reference tests | “The verifier detected `[x/N]` defined integrity failures under the documented reference assumptions.” | Exclude unsupported attack claims; fix record-loss defects before demo. |
| Transfer reliability, if included | Interruptions, duplicate sends, conflicting IDs, acknowledgement loss | “Across `[N]` induced interruptions, `[x]` records were lost and `[y]` duplicate logical records remained.” | Drop automatic transfer and use manual export. |
| Usability | Friends complete capture, recapture, evidence review without coaching | “`[x/n]` student testers completed the tasks; these participants were not operational officers.” | Fix the largest observed friction; avoid officer-productivity claims. |

**Do not report “99% accurate” across unrelated tasks.** Publish raw counts, excluded cases, abstentions, and uncertainty. Where multiple images share a root or multiple comparisons share a person, uncertainty analysis must respect that grouping.

**Do not claim “0% false positives” because none occurred in a small pilot.** Say “zero observed among `[N]` tested examples,” and keep the population-level rate unknown.

## D10 — Repo scaffold and first 48 hours.

**First vertical slice:** live phone capture → bundled OCR → one supported field comparison → explicit result state → encrypted saved record → restart → same evidence recovered, all with radios disabled.

**Do not start with FastAPI, PostgreSQL, React, and a mobile app as four separate products.** The screening path belongs on the phone. A server can be added later without becoming a runtime dependency.

```text
screening/
├── README.md
├── .gitignore
├── app/
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/
│   │   │   ├── screening_result.dart
│   │   │   ├── mrz_parser.dart
│   │   │   ├── consistency_rules.dart
│   │   │   ├── decision_policy.dart
│   │   │   └── government_provider.dart
│   │   ├── capture/capture_screen.dart
│   │   ├── evidence/evidence_screen.dart
│   │   ├── storage/record_repository.dart
│   │   ├── audit/audit_chain.dart
│   │   └── report/report_view.dart
│   ├── android/app/src/main/kotlin/.../
│   │   ├── OcrBridge.kt
│   │   ├── CryptoStore.kt
│   │   └── ModelBridge.kt
│   ├── assets/
│   │   ├── models/model_manifest.json
│   │   └── fixtures/
│   ├── test/
│   └── integration_test/
├── contracts/
│   ├── screening_record.schema.json
│   └── example_record.json
├── data/
│   ├── README.md
│   ├── provenance.csv
│   └── splits.json
├── ml/
│   ├── generate.py
│   ├── train.py
│   ├── evaluate.py
│   └── export_model.py
├── scripts/
│   ├── verify_audit.py
│   └── check_release.py
├── tests/
│   ├── fixtures/
│   └── protocols/
└── docs/
    ├── scope.md
    ├── threat-model.md
    ├── claims-register.md
    ├── data-protocol.md
    ├── model-card.md
    ├── metrics.md
    ├── demo-script.md
    └── release-checklist.md
```

**No face images, embeddings, consent forms, secrets, or private identity mappings in Git.** The tree is a proposed scaffold, not a claim that these files have been created.

| Minimum day-one files | Owner | Required content |
|---|---|---|
| README, scope, claims register | M1 + M6 | Supported input, prohibited claims, setup, owner map |
| Record schema and example | M1 | Versions, provenance, check states, reason codes, opaque record ID |
| Flutter app/capture/evidence shell | M2 + M5 | Camera path, visible labels, recoverable failure states |
| Bundled OCR bridge | M2 | Local image → extraction; no network fallback |
| Rules and government provider | M1 | One deterministic fixture; provider always `NOT_CONFIGURED` |
| Encrypted repository and native key wrapper | M4 | Encrypt-before-write; reopen test; no plaintext cache |
| Generator, provenance, split manifest | M3 | Fixed seed, original fictional assets, family grouping |
| Test protocol and ten fixtures | M6 | Expected states independently checked |

**[ASSUMPTION] Six focused work hours per day.** The remaining calendar time is not silently treated as overtime. Each person reserves the final work hour for integration or review.

| Day/hour | M1 — Lead | M2 — Mobile | M3 — ML/data | M4 — Security | M5 — Experience | M6 — QA |
|---|---|---|---|---|---|---|
| **17 / H1** | Freeze narrow scope and owner map | Create/install Flutter app | Define fictional template fields | Define encrypted-record boundary | Sketch capture/evidence states | Write acceptance checklist |
| **17 / H2** | Define result schema | Wire camera and permissions | Create original template artwork | Implement device-key access | Build TEST DATA banner and shell | Write source/provenance register |
| **17 / H3** | Implement one comparison rule | Bundle OCR dependency | Implement fixed-seed rendering | Encrypt/decrypt synthetic payload | Render schema fixture | Create clean/mismatch fixtures |
| **17 / H4** | Implement explicit unavailable states | Connect capture to OCR | Generate initial fixtures | Persist and reopen encrypted payload | Display reasons and source values | Independently check expected results |
| **17 / H5** | Connect rule to extracted fields | Test first launch offline | Add root IDs and manifest | Inspect app-created temporary files | Bind live extraction output | Run device smoke test |
| **17 / H6** | Merge and resolve interface issues | Fix mobile blocker | Review fixture integration | Review persistence integration | Fix UI integration | Record failures and day-two priorities |
| **18 / H1** | Extend supported parser | Correct rotation/cropping issues | Define family split | Implement atomic record save | Build history list | Test malformed/unsupported inputs |
| **18 / H2** | Add date/field tests | Preserve original image bytes | Implement controlled alterations | Connect encrypted image and result | Open saved evidence | Review labels on every state |
| **18 / H3** | Connect rule reasons | Handle camera denial/errors | Add clean processing controls | Add recovery after interruption | Add recapture action | Run ten-case offline suite |
| **18 / H4** | Version rule policy | Build/install release-mode APK | Check split overlap | Force-close during save tests | Fix evidence readability | Test on second phone |
| **18 / H5** | Resolve critical integration defects | Fix actual device failures | Commit generation manifest | Check no completed record lost | Complete recovered-record flow | Verify fresh-install offline path |
| **18 / H6** | Accept/reject vertical slice | Demonstrate phone flow | Hand off dataset instructions | Demonstrate restart recovery | Demonstrate evidence navigation | Save pass/fail report and next cut decisions |

**End-of-48-hours done test:** M6, using M2’s installation instructions, captures a labelled mismatch, gets the expected reason, force-closes the app, and recovers the same record without enabling a radio.

## D11 — Submission package.

**Use exactly five main content slides.** Follow the actual official template if its required ordering differs.

**[verified, historical only]** SIH’s published 2024 guidelines include novelty, complexity, clarity, feasibility, practicability, sustainability, scale of impact, user experience, and future progression. **[needs checking]** These do not establish the exact 2026 rubric or weights. Your requested dimensions below are a useful mapping, not a verified quotation of this year’s criteria. [Official 2024 guidelines, page 20](https://sih.gov.in/letters/Guidelines-College-SPOC.pdf)

| Slide | Content | Criteria addressed | One line that carries it | Owner |
|---|---|---|---|---|
| **1 — Problem and bounded promise** | Officer workflow hypothesis; supported fictional document; connectivity constraint; explicit human referral | Impact, clarity | **“Preserve a useful screening decision even when the phone has no connection.”** | M1 + M6 |
| **2 — What the prototype proves** | Capture → consistency check → evidence → restart recovery; competitor acknowledgment; one real screenshot | Novelty as demonstrated contribution, user experience | **“Our contribution is a testable offline workflow with visible evidence and limits.”** | M5 + M2 |
| **3 — Architecture and security** | Phone boundary, bundled OCR/model, local rules, encrypted record, independently retained audit reference, `NOT_CONFIGURED` interface | Technical depth, feasibility | **“The phone performs screening; every unavailable authority check stays unavailable.”** | M4 + M1 |
| **4 — Evidence and limitations** | Device latency, OCR fields, false referrals, dataset roots/families, independent-edit result; disabled modules visibly listed | Feasibility, technical depth | **“These are the measured results—and the conditions where we abstain or fail.”** | M3 + M6 |
| **5 — Delivery and next evaluation** | What ships, six-owner plan, cuts, future supervised evaluation, device/operations costs, unvalidated scaling assumptions | Scalability, impact, practicality | **“A bounded prototype now; broader claims only after broader evidence.”** | M1 + M5 |

**Do not fill slide 4 with target numbers.** Before evaluation, label it “evaluation protocol”; after evaluation, replace targets with actual measurements.

| Supporting artifact | Contents | Owner |
|---|---|---|
| Release APK and manifest | Build identifier, model versions, hashes, tested devices, installation instructions | M2 |
| Reproducibility pack | Fictional generator, seed, dependencies, split definitions, permitted assets | M3 |
| Evaluation report | Raw counts, failure cases, denominators, conditions, frozen configuration | M6 |
| Security note | Threat model, encryption boundary, chain limits, retained-reference procedure | M4 |
| Claims/source register | Statement, supporting source or experiment, status, permitted wording | M6 |
| Five-slide PDF | Offline-openable, readable, no unsupported institutional statistics | M5 |
| Demo kit | Labelled specimens, backup phone, reset instructions, permitted contingency recording | M2 + M5 |
| Requirements traceability | Full official PS when available; map each requirement to implemented/tested/planned/excluded | M1 |

## D12 — The cut list.

**A six-person student team can plausibly deliver a narrow, tested Android workflow in the assumed window. It cannot credibly validate a broad border-screening platform, establish operational biometric accuracy, prove fraud-ring attribution, and support multiple mobile platforms in that same window.**

| Drop order | Master-document item or proposed expansion | Decision | What the demo loses |
|---|---|---|---|
| **1** | Government database behavior beyond an unavailable interface | **Prohibited, not a future stretch task for this prototype.** No mock hits, fake authority responses, or attempted access. | Nothing defensible; removes misleading drama. |
| **2** | NFC, ePassport chip reading, full PKI | **Drop.** Requires a separate technically and evidentially sound workflow. | Chip-authenticity demonstration. |
| **3** | Operational liveness | **Drop.** Blink/head-turn functionality is too easily mistaken for proven spoof resistance. | A theatrical interaction; avoids an unsupported security claim. |
| **4** | Full iOS/Android/web screening parity | **Drop from deadline commitment.** Android first; browser report only if core is stable. | Immediate multi-platform inference claim. |
| **5** | React Native | **Replace with Flutter/Kotlin.** | Nothing relevant to judges; avoids unnecessary learning cost. |
| **6** | Broad passport/visa/ID/driving-licence/Aadhaar coverage | **One supported fictional passport-style layout.** Aadhaar support excluded; its applicable requirements remain separate **[needs checking for any future implementation]**. | Breadth; gains testable behavior. |
| **7** | Fraud-ring map, geospatial display, graph, timeline | **Drop graphics first.** If earned, keep a pair-comparison list with crops. | Visual spectacle; preserves inspectable evidence. |
| **8** | Five-class tamper classifier and polished heatmap | **Binary experimental classifier only, if tests pass.** No heatmap claimed as accurate localization without evaluation. | Detailed attack labels and dramatic overlays. |
| **9** | Automatic multi-device synchronization | **Conditional; manual export is the default fallback.** | Live central aggregation; preserves local screening and records. |
| **10** | Separate FastAPI/PostgreSQL/React operational platform | **Drop from the critical path.** | Central administration and enterprise-looking dashboards. |
| **11** | Full four-role authorization system | **Drop simulated role security.** Use explicit prototype views and a local access boundary; document unimplemented organizational controls. | A production access-management claim. |
| **12** | Face verification as a mandatory stage | **Make optional and removable.** Require model permission, local execution, and disclosed pilot evaluation. | Impersonation beat; core document screening still works. |
| **13** | ELA, noise, edges, font deviations, stamp hash, and class distributions combined into one elaborate fingerprint | **Reduce to one interpretable artifact experiment.** | A large feature list whose reliability cannot be established. |
| **14** | Weighted green/yellow/red “risk” score | **Replace with explicit reasoned states.** Experimental signals remain separately labelled. | A visually simple number; gains defensible semantics. |
| **15** | Sophisticated automatic document boundaries and dewarping | **Manual guide/crop first.** Add automation only after physical-photo testing justifies it. | Capture polish; retains a usable input path. |
| **16** | Claims of zero new hardware procurement | **Replace with “tested on these existing phones.”** | Unsupported procurement savings. |
| **17** | “Production-ready,” “investigation-grade,” or “tamper-proof” language | **Delete.** | Inflated positioning; no working capability is lost. |
| **18** | New optional features after 26 September | **Freeze.** Remaining effort goes to defect fixes, test evidence, handoffs, and rehearsal. | Last-minute breadth; preserves a complete demonstration. |