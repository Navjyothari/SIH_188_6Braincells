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
              Icon(Icons.face_retouching_natural,
                  size: 20, color: Colors.blueGrey.shade400),
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
            if (r.similarityScore != null) ...[
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
                tooltip:
                    'Versioned EdgeFace threshold, frozen before held-out evaluation.',
              ),
              _DetailRow(
                label: 'Model',
                value: r.modelVersion,
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
        FaceVerificationStatus.match => Colors.green,
        FaceVerificationStatus.noMatch => Colors.red,
        FaceVerificationStatus.uncertain => Colors.orange,
        FaceVerificationStatus.notRun => Colors.grey,
        FaceVerificationStatus.recapture => Colors.orange,
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
      FaceVerificationStatus.match => (
          Colors.green.shade700,
          Icons.check_circle_rounded,
          'MATCH'
        ),
      FaceVerificationStatus.noMatch => (
          Colors.red.shade700,
          Icons.cancel_rounded,
          'NO MATCH'
        ),
      FaceVerificationStatus.uncertain => (
          Colors.orange.shade800,
          Icons.help_rounded,
          'UNCERTAIN'
        ),
      FaceVerificationStatus.recapture => (
          Colors.orange.shade800,
          Icons.camera_alt_outlined,
          'RETAKE SELFIE'
        ),
      FaceVerificationStatus.notRun => (
          Colors.grey.shade600,
          Icons.remove_circle_outline_rounded,
          'NOT RUN'
        ),
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
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500),
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
    final reasonText = isSkipped
        ? 'Face check was skipped. No similarity score was produced.'
        : result.explanation;

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
        'The comparison module does not save face crops or embeddings.',
        style: TextStyle(fontSize: 10, color: Colors.black87),
      ),
    );
  }
}
