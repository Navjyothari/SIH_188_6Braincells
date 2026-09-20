# Phase 1 result test guide

The only screening rule is consistency between DOCUMENT NUMBER and REPEATED NUMBER on the labelled FICTIONAL PASSPORT ALPHA layout. No date, name, portrait, authenticity, or government-database check is implemented or required by this Phase 1 rule.

## Decision order

1. Fewer than 20 readable characters after whitespace normalization: RECAPTURE.
2. Either exact header line missing (FICTIONAL PASSPORT ALPHA or SPECIMEN - NOT VALID FOR TRAVEL): UNSUPPORTED. A cropped or misread header can also cause this result; it is not a fraud finding.
3. Each number must appear exactly once and have TEST followed by six digits. Missing, duplicate (even identical), malformed, or ambiguous fields: RECAPTURE. The parser does not silently change O to 0 or I to 1.
4. Two valid unequal numbers: REVIEW_REQUIRED. The explanation names both values and notes that OCR error may cause a mismatch.
5. Two valid equal numbers: NO_INCONSISTENCY_DETECTED. Only this number comparison passed; authenticity and identity are not established.

Case and repeated whitespace are normalized. Field values may follow their label on the same line (with or without a colon), or immediately on the next line. Government verification is always NOT_CONFIGURED.

## On-phone cases

Keep airplane mode enabled and Wi-Fi off. Display fictional specimens on another screen or paper, and include their complete headers unless testing a missing header.

| Input | Expected result |
|---|---|
| 01-clean.png: TEST558198 / TEST558198 | NO INCONSISTENCY DETECTED |
| 01-altered.png: TEST558198 / TEST558199 | REVIEW REQUIRED; both numbers in explanation |
| Cover just the repeated number, leaving headers readable | RECAPTURE |
| Cover just the document number, leaving headers readable | RECAPTURE |
| Blank or almost unreadable image | RECAPTURE if OCR yields too little text |
| Unrelated readable document, or cover the fictional layout header | UNSUPPORTED if enough other text is read |
| Both numbers changed to the same valid TEST + six digits | NO INCONSISTENCY DETECTED; illustrates the rule's limit |
| Name/date/portrait changed but two valid numbers still match | NO INCONSISTENCY DETECTED; those changes are outside this rule |

For an unexpected result, expand Original OCR text and compare what was actually read with the decision order. A photograph alone cannot guarantee exact OCR text: for example, a blurred header can produce UNSUPPORTED rather than RECAPTURE. Never reinterpret a result as proof of fraud or authenticity.

RECAPTURE and UNSUPPORTED can be saved as evidence of an inconclusive screening attempt. An encrypted-save message means persistence succeeded, not that the document passed. Camera cancellation and OCR execution failure create no completed record. A save failure must show NOT SAVED and offer retry.

For every result, verify the explanation, original capture, NOT_CONFIGURED, and synthetic label. Force-stop and reopen the same record; repeat after actual reboot and unlock. Fresh-install first launch offline must be tested separately on a disposable installation without deleting existing evidence.

Automated parser tests cover all four states, both fields' missing/invalid/duplicate cases, header precedence, normalization, and all ten specimen text references. Mocked workflow tests cover display/save/reopen for every state; they do not replace physical camera/OCR or encryption tests.

## Automated verification - 20 September 2026

Expanded suite: 43 Flutter tests passed. Static analysis of lib and test: no issues. These changes add tests and documentation only; the installed app behavior is unchanged. Physical checks still pending are recorded in phase1-acceptance.md.
