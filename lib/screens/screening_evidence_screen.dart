// lib/screens/screening_evidence_screen.dart
// M3 Integration — Step 3: Combined Evidence Screen
//
// Shows the full result of one screening session:
//   Section A: Document OCR + Rule Checks
//   Section B: Face Verification (M3 — optional, decoupled)
//
// Design invariants:
//   - Section A and Section B are rendered independently.
//     A face check NOT_RUN does NOT hide or block the OCR section.
//   - Face verification is explicitly labelled as experimental and
//     optional — never implies a definitive clearance or failure.
//   - "New Screening" resets the session and returns to Step 1.
//   - All data is labelled SPECIMEN / SYNTHETIC as required by project rules.
//   - No "cleared" or "authentic" language is used anywhere in this screen.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/screening_session.dart';
import '../widgets/face_verification_result_card.dart';

class ScreeningEvidenceScreen extends StatelessWidget {
  const ScreeningEvidenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ScreeningSession>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          'Screening Evidence',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          // Specimen label — always visible per project rules
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.amber.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'SPECIMEN / SYNTHETIC',
              style: TextStyle(
                  color: Colors.amber.shade400,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------------------------------------------------------------
              // Session header — document thumbnail + meta
              // ---------------------------------------------------------------
              _SessionHeader(session: session),
              const SizedBox(height: 16),

              // ---------------------------------------------------------------
              // Section A: OCR + Rule Results
              // Independent of face verification — always shown.
              // ---------------------------------------------------------------
              _SectionLabel(
                icon: Icons.document_scanner_rounded,
                label: 'Document OCR & Consistency Checks',
              ),
              const SizedBox(height: 8),
              _OcrResultCard(ocrResult: session.ocrResult),
              const SizedBox(height: 20),

              // ---------------------------------------------------------------
              // Section B: Face Verification (M3 — optional)
              // If face check did not run, this section still appears and
              // explains why — it does not suppress or hide itself.
              // ---------------------------------------------------------------
              _SectionLabel(
                icon: Icons.face_retouching_natural,
                label: 'Face Verification (optional)',
              ),
              const SizedBox(height: 8),
              FaceVerificationResultCard(result: session.faceResult),
              const SizedBox(height: 8),
              // Show the selfie thumbnail if one was captured
              if (session.selfieImagePath != null)
                _SelfieThumbRow(selfieImagePath: session.selfieImagePath!),
              const SizedBox(height: 24),

              // ---------------------------------------------------------------
              // Government verification — always NOT_CONFIGURED
              // ---------------------------------------------------------------
              _NotConfiguredBanner(
                icon: Icons.account_balance_rounded,
                label: 'Authoritative Government Verification',
                state: 'NOT_CONFIGURED',
              ),
              const SizedBox(height: 24),

              // ---------------------------------------------------------------
              // "New Screening" action
              // ---------------------------------------------------------------
              OutlinedButton.icon(
                onPressed: () {
                  session.reset();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('New Screening'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF58A6FF),
                  side: const BorderSide(color: Color(0xFF30363D)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),

              // ---------------------------------------------------------------
              // Bottom disclaimer
              // ---------------------------------------------------------------
              _BottomDisclaimer(),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: const Color(0xFF58A6FF)),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF8B949E),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
      const Expanded(child: Divider(color: Color(0xFF30363D), indent: 12)),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Session header — document capture thumbnail + step summary
// ---------------------------------------------------------------------------

class _SessionHeader extends StatelessWidget {
  final ScreeningSession session;
  const _SessionHeader({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        children: [
          // Document thumbnail
          if (session.documentImagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                File(session.documentImagePath!),
                width: 72,
                height: 56,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 72,
              height: 56,
              decoration: BoxDecoration(
                  color: const Color(0xFF21262D),
                  borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.document_scanner_rounded,
                  color: Color(0xFF30363D), size: 28),
            ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Screening Session',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
              const SizedBox(height: 4),
              _StepChip(
                  label: 'Document',
                  done: session.documentImagePath != null),
              const SizedBox(height: 3),
              _StepChip(
                  label: 'Selfie',
                  done: session.selfieImagePath != null,
                  optional: true),
              const SizedBox(height: 3),
              _StepChip(
                  label: 'Face Check',
                  done: session.faceResult != null,
                  optional: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  final String label;
  final bool done;
  final bool optional;
  const _StepChip({required this.label, required this.done, this.optional = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 12,
          color: done ? Colors.green.shade400 : Colors.grey.shade600,
        ),
        const SizedBox(width: 5),
        Text(
          '$label${optional ? " (optional)" : ""}',
          style: TextStyle(
              color: done ? Colors.grey.shade300 : Colors.grey.shade600,
              fontSize: 11),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// OCR Result Card (shows stub result; replace with real OCR binding)
// ---------------------------------------------------------------------------

class _OcrResultCard extends StatelessWidget {
  final OcrResult ocrResult;
  const _OcrResultCard({required this.ocrResult});

  @override
  Widget build(BuildContext context) {
    if (!ocrResult.isAvailable) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: Row(children: [
          Icon(Icons.hourglass_empty_rounded, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            ocrResult.state == 'PENDING'
                ? 'OCR not yet run for this session.'
                : 'OCR unavailable.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ]),
      );
    }

    final stateColor = switch (ocrResult.state) {
      'NO_INCONSISTENCY_DETECTED' => Colors.green.shade600,
      'REVIEW_REQUIRED'           => Colors.orange.shade600,
      'UNSUPPORTED'               => Colors.grey.shade500,
      'RECAPTURE'                 => Colors.red.shade600,
      _                           => Colors.grey.shade500,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: stateColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // State badge
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: stateColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: stateColor.withOpacity(0.4)),
              ),
              child: Text(
                ocrResult.state,
                style: TextStyle(
                    color: stateColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5),
              ),
            ),
            if (ocrResult.documentType != null) ...[
              const SizedBox(width: 10),
              Text(
                ocrResult.documentType!,
                style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12),
              ),
            ],
          ]),

          // Flagged rules
          if (ocrResult.flaggedRules.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Flagged inconsistencies:',
              style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ...ocrResult.flaggedRules.map((rule) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 14, color: Colors.orange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          rule,
                          style: const TextStyle(
                              color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          // Extracted fields
          if (ocrResult.extractedFields.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Extracted fields:',
              style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ...ocrResult.extractedFields.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          e.key,
                          style: const TextStyle(
                              color: Color(0xFF8B949E), fontSize: 11),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          e.value,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          // Development stub notice
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade900.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue.shade900.withOpacity(0.4)),
            ),
            child: const Text(
              'DEV STUB: Replace with real OCR module output when wired.',
              style: TextStyle(fontSize: 10, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Selfie thumbnail row
// ---------------------------------------------------------------------------

class _SelfieThumbRow extends StatelessWidget {
  final String selfieImagePath;
  const _SelfieThumbRow({required this.selfieImagePath});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.person_rounded, size: 14, color: Color(0xFF8B949E)),
        const SizedBox(width: 6),
        const Text('Selfie captured:',
            style: TextStyle(color: Color(0xFF8B949E), fontSize: 11)),
        const SizedBox(width: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.file(File(selfieImagePath),
              width: 40, height: 40, fit: BoxFit.cover),
        ),
        const SizedBox(width: 6),
        const Text(
          'Not stored beyond this session.',
          style: TextStyle(color: Color(0xFF8B949E), fontSize: 10),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Government verification — always NOT_CONFIGURED
// ---------------------------------------------------------------------------

class _NotConfiguredBanner extends StatelessWidget {
  final IconData icon;
  final String label;
  final String state;
  const _NotConfiguredBanner(
      {required this.icon, required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            state,
            style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4),
          ),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom disclaimer
// ---------------------------------------------------------------------------

class _BottomDisclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade900.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade900.withOpacity(0.3)),
      ),
      child: const Text(
        'This screen shows investigative indicators only. '
        'All fields are from a fictional/synthetic specimen. '
        'A human officer must make all final decisions. '
        'Results are NOT a determination of document authenticity, '
        'identity, or travel permission.',
        style: TextStyle(fontSize: 10, color: Colors.amber),
        textAlign: TextAlign.center,
      ),
    );
  }
}
