// face_verification_widget.dart
// M3 — Face Verification Module (optional, removable)
//
// Self-contained UI widget for the face verification flow.
// Drop this into any screen. If the module is disabled, it renders
// a neutral "not available" state — it never shows a fake result.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'face_verification_result.dart';
import 'face_verification_service.dart';

/// FaceVerificationWidget — optional M3 module UI.
///
/// Shows:
///   1. A "Capture live face" button (camera).
///   2. An optional "Choose reference image" button.
///   3. A result badge showing MATCH / NO_MATCH / UNCERTAIN / NOT_RUN.
///   4. A score row (similarity + threshold) for transparency.
///   5. A disclaimer that this is experimental.
///
/// When [service.enabled] is false, renders [_DisabledState].
class FaceVerificationWidget extends StatefulWidget {
  final FaceVerificationService service;

  /// Optional pre-selected reference image path. When null, the bundled
  /// synthetic reference is used on the Kotlin side.
  final String? referenceImagePath;

  const FaceVerificationWidget({
    super.key,
    required this.service,
    this.referenceImagePath,
  });

  @override
  State<FaceVerificationWidget> createState() => _FaceVerificationWidgetState();
}

class _FaceVerificationWidgetState extends State<FaceVerificationWidget> {
  final _picker = ImagePicker();

  String? _liveImagePath;
  FaceVerificationResult _result = FaceVerificationResult.notRun();
  bool _isProcessing = false;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (!widget.service.enabled) return const _DisabledState();

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              icon: Icons.face_retouching_natural,
              label: 'Face Verification (M3 — experimental)',
            ),
            const SizedBox(height: 12),
            _ExperimentalDisclaimer(),
            const SizedBox(height: 16),
            _CaptureRow(
              liveImagePath: _liveImagePath,
              onCapture: _captureAndVerify,
            ),
            if (_liveImagePath != null) ...[
              const SizedBox(height: 16),
              _ResultBadge(result: _result),
              if (_result.status != FaceVerificationStatus.notRun) ...[
                const SizedBox(height: 8),
                _ScoreRow(result: _result),
              ],
            ],
            if (_isProcessing) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _captureAndVerify() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 640,
      maxHeight: 640,
      imageQuality: 90,
      preferFrontCamera: true,
    );
    if (picked == null) return;

    setState(() {
      _liveImagePath = picked.path;
      _isProcessing  = true;
      _result        = FaceVerificationResult.notRun();
    });

    final result = await widget.service.verifyFace(
      liveImagePath:      picked.path,
      referenceImagePath: widget.referenceImagePath,
    );

    setState(() {
      _result       = result;
      _isProcessing = false;
    });
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 20, color: Colors.blueGrey),
      const SizedBox(width: 8),
      Text(label,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold)),
    ]);
  }
}

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
        'Experimental module — similarity score only. '
        'This is NOT a forgery or authenticity determination. '
        'Results are indicative; do not use as sole evidence.',
        style: TextStyle(fontSize: 11, color: Colors.black87),
      ),
    );
  }
}

class _CaptureRow extends StatelessWidget {
  final String? liveImagePath;
  final VoidCallback onCapture;
  const _CaptureRow({required this.liveImagePath, required this.onCapture});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      ElevatedButton.icon(
        onPressed: onCapture,
        icon: const Icon(Icons.camera_alt, size: 18),
        label: Text(liveImagePath == null ? 'Capture live face' : 'Re-capture'),
      ),
      if (liveImagePath != null) ...[
        const SizedBox(width: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.file(File(liveImagePath!),
              width: 48, height: 48, fit: BoxFit.cover),
        ),
      ],
    ]);
  }
}

class _ResultBadge extends StatelessWidget {
  final FaceVerificationResult result;
  const _ResultBadge({required this.result});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (result.status) {
      FaceVerificationStatus.match     => (Colors.green,  Icons.check_circle),
      FaceVerificationStatus.noMatch   => (Colors.red,    Icons.cancel),
      FaceVerificationStatus.uncertain => (Colors.orange, Icons.help),
      FaceVerificationStatus.notRun    => (Colors.grey,   Icons.remove_circle_outline),
    };

    return Row(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(width: 8),
      Text(result.displayLabel,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 15)),
    ]);
  }
}

class _ScoreRow extends StatelessWidget {
  final FaceVerificationResult result;
  const _ScoreRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final score = result.similarityScore;
    final thresh = result.thresholdUsed;
    return Text(
      'Similarity: ${score != null ? score.toStringAsFixed(3) : "—"}  '
      '| Threshold: ${thresh != null ? thresh.toStringAsFixed(2) : "—"}  '
      '| Model: ${result.modelVersion}',
      style: const TextStyle(fontSize: 11, color: Colors.black54),
    );
  }
}

class _DisabledState extends StatelessWidget {
  const _DisabledState();
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(children: [
          Icon(Icons.face_retouching_off, color: Colors.grey),
          SizedBox(width: 8),
          Text('Face verification module: NOT_RUN (disabled)',
              style: TextStyle(color: Colors.grey)),
        ]),
      ),
    );
  }
}
