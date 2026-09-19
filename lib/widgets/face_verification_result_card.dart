// lib/widgets/face_verification_result_card.dart
// M3 — Face Verification Module
//
// A self-contained display card for FaceVerificationResult that can be
// embedded in ScreeningEvidenceScreen alongside OCR rule results.
//
// Design decisions:
//   - Shows all four contract fields: status, similarityScore,
//     thresholdUsed, modelVersion — never hides any field.
//   - NOT_RUN is always clearly labelled. If the modelVersion is
//     'not-run/skipped-by-officer', the reason is surfaced explicitly.
//   - UNCERTAIN uses amber, not red — it is not a definitive mismatch.
//   - The experimental disclaimer always appears; it cannot be removed
//     by the caller. Per project rules, similarity is not an
//     authenticity or forgery signal.
//   - No tap interaction is provided; this is a read-only result display.

import 'dart:io';
import 'package:flutter/material.dart';
import '../modules/face_verification/face_verification_result.dart';

class FaceVerificationResultCard extends StatelessWidget {
  /// The result to display. Pass null to show a "not yet run" placeholder.
  final FaceVerificationResult? result;

  const FaceVerificationResultCard({super.key, this.result});

  @override
  Widget build(BuildContext context) {
    final r = result ?? FaceVerificationResult.notRun();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _borderColor(r.status).withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------------------
            // Header row
            // ----------------------------------------------------------------
            Row(children: [
              Icon(Icons.face_retouching_natural, size: 20, color: Colors.blueGrey.shade400),
              const SizedBox(width: 8),
              Text(
                'Face Verification (M3 — experimental)',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ]),
            const SizedBox(height: 12),

            // ----------------------------------------------------------------
            // Status badge — most prominent element
            // ----------------------------------------------------------------
            _StatusBadge(status: r.status, modelVersion: r.modelVersion),
            const SizedBox(height: 12),

            // ----------------------------------------------------------------
            // Detail rows (score, threshold, model) — only when ran
            // ----------------------------------------------------------------
            if (r.status != FaceVerificationStatus.notRun) ...[
              _DetailRow(
                label: 'Similarity score',
                value: r.similarityScore != null
                    ? r.similarityScore!.toStringAsFixed(4)
                    : '—',
                tooltip: 'Cosine similarity ∈ [−1, 1]. '
                    'Higher = more similar faces. '
                    'NOT an authenticity or forgery probability.',
              ),
              _DetailRow(
                label: 'MATCH threshold',
                value: r.thresholdUsed != null
                    ? '≥ ${r.thresholdUsed!.toStringAsFixed(2)}'
                    : '—',
                tooltip: 'Fixed on 20-pair synthetic dev set (DiffusionFace AAAI 2024). '
                    'Not tuned on test or demo data.',
              ),
              _DetailRow(
                label: 'Model',
                value: r.modelVersion,
              ),
              if (r.liveCropPath != null || r.refCropPath != null)
                _DebugCropsRow(
                  livePath: r.liveCropPath,
                  refPath: r.refCropPath,
                ),
            ] else ...[
              // NOT_RUN detail
              _NotRunDetail(result: r),
            ],

            const SizedBox(height: 12),

            // ----------------------------------------------------------------
            // Mandatory experimental disclaimer — always visible
            // ----------------------------------------------------------------
            _ExperimentalDisclaimer(),
          ],
        ),
      ),
    );
  }

  Color _borderColor(FaceVerificationStatus status) => switch (status) {
        FaceVerificationStatus.match     => Colors.green,
        FaceVerificationStatus.noMatch   => Colors.red,
        FaceVerificationStatus.uncertain => Colors.orange,
        FaceVerificationStatus.notRun    => Colors.grey,
      };
}

// ---------------------------------------------------------------------------
// Status badge
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  final FaceVerificationStatus status;
  final String modelVersion;

  const _StatusBadge({required this.status, required this.modelVersion});

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (status) {
      FaceVerificationStatus.match =>
        (Colors.green.shade700, Icons.check_circle_rounded, 'MATCH'),
      FaceVerificationStatus.noMatch =>
        (Colors.red.shade700, Icons.cancel_rounded, 'NO MATCH'),
      FaceVerificationStatus.uncertain =>
        (Colors.orange.shade800, Icons.help_rounded, 'UNCERTAIN'),
      FaceVerificationStatus.notRun =>
        (Colors.grey.shade600, Icons.remove_circle_outline_rounded, 'NOT RUN'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.6,
              ),
            ),
            if (status == FaceVerificationStatus.uncertain)
              Text(
                'Human review recommended',
                style: TextStyle(color: color, fontSize: 11),
              ),
          ],
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail rows (score, threshold, model)
// ---------------------------------------------------------------------------

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final String? tooltip;

  const _DetailRow({required this.label, required this.value, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: tooltip != null
                ? Tooltip(
                    message: tooltip!,
                    child: Text(
                      value,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          fontFamily: 'monospace'),
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        fontFamily: 'monospace'),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// NOT_RUN detail — explains why the check did not run
// ---------------------------------------------------------------------------

class _NotRunDetail extends StatelessWidget {
  final FaceVerificationResult result;
  const _NotRunDetail({required this.result});

  @override
  Widget build(BuildContext context) {
    final isSkipped = result.modelVersion == 'not-run/skipped-by-officer';
    String reasonText;
    if (isSkipped) {
      reasonText = 'Face check was skipped by the officer.\n'
          'This is permitted. No similarity score was produced.';
    } else if (result.debugInfo != null) {
      reasonText = 'Face check did not run.\n[DEBUG]\n${result.debugInfo!}';
    } else {
      reasonText = 'Face check did not run. Possible reasons:\n'
          '  • No face detected in document photo\n'
          '  • No face detected in selfie capture\n'
          '  • Module unavailable (model asset missing)\n'
          'OCR and rule results above are unaffected.';
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSkipped ? Icons.skip_next_rounded : Icons.info_outline,
            size: 18,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reasonText,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mandatory experimental disclaimer
// ---------------------------------------------------------------------------

class _ExperimentalDisclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        '⚠ Experimental — similarity score only. '
        'NOT an authenticity or forgery signal. '
        'Results are indicative only; a human officer makes all final decisions. '
        'No face image or embedding is stored.',
        style: TextStyle(fontSize: 10, color: Colors.black87),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Debug Crops display
// ---------------------------------------------------------------------------

class _DebugCropsRow extends StatelessWidget {
  final String? livePath;
  final String? refPath;

  const _DebugCropsRow({this.livePath, this.refPath});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '[DEBUG] Aligned Crops (112x112):',
            style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (refPath != null) ...[
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
                      child: Image.file(File(refPath!), width: 56, height: 56, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 2),
                    const Text('Doc', style: TextStyle(fontSize: 9, color: Colors.black54)),
                  ],
                ),
                const SizedBox(width: 12),
              ],
              if (livePath != null) ...[
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
                      child: Image.file(File(livePath!), width: 56, height: 56, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 2),
                    const Text('Live', style: TextStyle(fontSize: 9, color: Colors.black54)),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
