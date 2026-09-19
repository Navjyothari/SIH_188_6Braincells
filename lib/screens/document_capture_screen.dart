// lib/screens/document_capture_screen.dart
// M3 Integration — Step 1: Document Capture
//
// This screen captures the document photo using the REAR camera
// via image_picker. The same photo is used for two purposes:
//   (a) OCR / rule-check input (handed to the OCR module)
//   (b) Reference image for face verification (the Kotlin ML Kit
//       detector finds the printed portrait within it; no separate
//       cropping is needed on the Flutter side)
//
// Image quality settings are set deliberately high to ensure:
//   - The printed face photo on the document is large enough for
//     ML Kit's face detector to find it (minimum ~60×60 px face region).
//   - Fine text in the MRZ and other fields remains legible for OCR.
//
// The captured file path is saved to ScreeningSession.documentImagePath.
// A separate "Save to permanent storage" step is the responsibility of
// the evidence persistence layer — not this screen.
//
// After capture is confirmed, navigates to '/selfie'.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../app/screening_session.dart';

class DocumentCaptureScreen extends StatefulWidget {
  const DocumentCaptureScreen({super.key});

  @override
  State<DocumentCaptureScreen> createState() => _DocumentCaptureScreenState();
}

class _DocumentCaptureScreenState extends State<DocumentCaptureScreen> {
  final _picker = ImagePicker();
  String? _capturedPath;
  bool _isCapturing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        foregroundColor: Colors.white,
        title: const Text(
          'Step 1 — Capture Document',
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------------------------------------------------------------
              // Instructions panel
              // ---------------------------------------------------------------
              _InstructionCard(
                steps: const [
                  'Place document flat on a dark surface.',
                  'Ensure the photo/portrait area is clearly visible.',
                  'Fill the frame; avoid glare and heavy shadows.',
                  'Photograph in good lighting — the printed face must be detectable.',
                ],
              ),
              const SizedBox(height: 20),

              // ---------------------------------------------------------------
              // Preview area (shows captured image or placeholder)
              // ---------------------------------------------------------------
              Expanded(
                child: _capturedPath == null
                    ? _CapturePrompt(onCapture: _captureDocument)
                    : _CapturePreview(
                        imagePath: _capturedPath!,
                        onRetake: _retake,
                      ),
              ),

              const SizedBox(height: 20),

              // ---------------------------------------------------------------
              // Confirm / Continue button (only shown after capture)
              // ---------------------------------------------------------------
              if (_capturedPath != null)
                FilledButton.icon(
                  onPressed: _isCapturing ? null : _confirmAndProceed,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Confirm & continue to selfie'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF238636),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),

              if (_isCapturing)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Actions
  // --------------------------------------------------------------------------

  Future<void> _captureDocument() async {
    setState(() => _isCapturing = true);

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,  // rear camera for document
        // -----------------------------------------------------------------
        // Image quality settings — deliberately NOT compressed aggressively.
        // maxWidth/maxHeight cap at 2048 to avoid huge files while keeping
        // the printed face region large enough for ML Kit detection.
        // imageQuality: 95 preserves enough detail for both OCR and the
        // face detector; lower values (e.g. 60-70) can blur fine features.
        // -----------------------------------------------------------------
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 95,
      );

      if (picked == null) {
        // User cancelled
        setState(() => _isCapturing = false);
        return;
      }

      setState(() {
        _capturedPath = picked.path;
        _isCapturing = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      setState(() => _isCapturing = false);
    }
  }

  void _retake() {
    setState(() => _capturedPath = null);
  }

  void _confirmAndProceed() {
    if (_capturedPath == null) return;
    // Write document path into session — this also resets selfie + face result.
    context.read<ScreeningSession>().setDocumentImage(_capturedPath!);
    Navigator.pushNamed(context, '/selfie');
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _InstructionCard extends StatelessWidget {
  final List<String> steps;
  const _InstructionCard({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.camera_alt_rounded, color: Color(0xFF58A6FF), size: 18),
            const SizedBox(width: 8),
            Text(
              'Document Capture Instructions',
              style: TextStyle(
                  color: Colors.grey.shade300,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ]),
          const SizedBox(height: 10),
          ...steps.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${e.key + 1}. ',
                      style: const TextStyle(
                          color: Color(0xFF58A6FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    Expanded(
                      child: Text(
                        e.value,
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _CapturePrompt extends StatelessWidget {
  final VoidCallback onCapture;
  const _CapturePrompt({required this.onCapture});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCapture,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFF30363D), width: 1.5, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.document_scanner_rounded,
                size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'Tap to open camera',
              style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(
              'Use rear camera',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapturePreview extends StatelessWidget {
  final String imagePath;
  final VoidCallback onRetake;
  const _CapturePreview({required this.imagePath, required this.onRetake});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: TextButton.icon(
            onPressed: onRetake,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retake'),
            style: TextButton.styleFrom(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ),
      ],
    );
  }
}
