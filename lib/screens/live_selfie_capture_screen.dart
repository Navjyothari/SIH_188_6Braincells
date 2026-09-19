// lib/screens/live_selfie_capture_screen.dart
// M3 Integration — Step 2: Live Selfie Capture
//
// This screen opens the FRONT-facing camera using the `camera` package,
// shows a live preview, and lets the officer capture a photo of the
// person standing at the checkpoint.
//
// Flow:
//   1. Camera opens on front-facing lens (CameraLensDirection.front).
//   2. Live preview fills the screen. Face is shown in real time.
//   3. Officer taps [Capture] — frame is frozen, preview stays visible.
//   4. Officer taps [Confirm] — face verification fires, spinner shown.
//   5. Navigates to '/result' with faceResult set on session.
//
// Skip:
//   - "Skip face verification" button is always visible.
//   - Tapping it calls session.skipFaceVerification(), sets NOT_RUN
//     with reason "skipped-by-officer", and navigates to '/result'.
//   - Per project rules, face verification must NEVER be a mandatory gate.
//     Skipping it does not block or affect the OCR/rule results.
//
// Retake:
//   - Before confirming, [Retake] re-opens the preview discarding the
//     captured still.
//
// Camera lifecycle:
//   - CameraController is initialised in initState.
//   - It is disposed in dispose() to release the camera hardware.
//   - If initialisation fails, a fallback error state is shown with
//     skip-only navigation — never blocks the evidence screen.

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../app/screening_session.dart';
import '../modules/face_verification/face_verification_service.dart';

class LiveSelfieCaptureScreen extends StatefulWidget {
  /// The FaceVerificationService instance — provided by main.dart.
  final FaceVerificationService faceService;

  const LiveSelfieCaptureScreen({super.key, required this.faceService});

  @override
  State<LiveSelfieCaptureScreen> createState() => _LiveSelfieCaptureScreenState();
}

class _LiveSelfieCaptureScreenState extends State<LiveSelfieCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initFuture;
  String? _capturedPath;   // non-null = photo taken, waiting for confirm
  bool _isVerifying = false;
  String? _cameraErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      ctrl.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  // --------------------------------------------------------------------------
  // Camera initialisation
  // --------------------------------------------------------------------------

  Future<void> _initCamera() async {
    setState(() => _cameraErrorMessage = null);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraErrorMessage =
            'No cameras found on this device.\nUse "Skip" to continue without face verification.');
        return;
      }

      // Prefer rear-facing camera
      final rearCam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final ctrl = CameraController(
        rearCam,
        ResolutionPreset.high,   // high = ~1080p on most devices
        enableAudio: false,       // no audio needed for face capture
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _controller = ctrl;
      _initFuture = ctrl.initialize();
      setState(() {});
    } catch (e) {
      setState(() => _cameraErrorMessage =
          'Could not open camera: $e\n\nYou can skip face verification below.');
    }
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ----------------------------------------------------------------
            // Camera preview or captured still
            // ----------------------------------------------------------------
            if (_cameraErrorMessage != null)
              _ErrorState(message: _cameraErrorMessage!)
            else if (_capturedPath != null)
              _CapturedStill(imagePath: _capturedPath!)
            else
              FutureBuilder<void>(
                future: _initFuture,
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const _LoadingCamera();
                  }
                  if (snap.hasError) {
                    return _ErrorState(
                        message: 'Camera initialisation failed:\n${snap.error}');
                  }
                  return _LivePreview(controller: _controller!);
                },
              ),

            // ----------------------------------------------------------------
            // Top bar (title + skip)
            // ----------------------------------------------------------------
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopBar(onSkip: _isVerifying ? null : _skip),
            ),

            // ----------------------------------------------------------------
            // Bottom control panel
            // ----------------------------------------------------------------
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _isVerifying
                  ? const _VerifyingIndicator()
                  : _capturedPath != null
                      ? _ConfirmPanel(
                          onRetake: _retake,
                          onConfirm: _verify,
                        )
                      : _CapturePanel(
                          onCapture: _cameraErrorMessage != null ? null : _capture,
                          onSkip: _skip,
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Actions
  // --------------------------------------------------------------------------

  /// Captures a still from the camera and freezes the preview.
  Future<void> _capture() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || ctrl.value.isTakingPicture) {
      return;
    }
    try {
      final xFile = await ctrl.takePicture();
      setState(() => _capturedPath = xFile.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Capture failed: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  /// Discards the captured still and resumes live preview.
  void _retake() {
    setState(() => _capturedPath = null);
  }

  /// Skips face verification entirely.
  /// Per project rules, this must NEVER be a blocking gate.
  void _skip() {
    context.read<ScreeningSession>().skipFaceVerification();
    Navigator.pushReplacementNamed(context, '/result');
  }

  /// Confirms the captured selfie and runs face verification.
  Future<void> _verify() async {
    final selfiePath = _capturedPath;
    if (selfiePath == null) return;

    final session = context.read<ScreeningSession>();
    final docPath = session.documentImagePath;

    if (docPath == null) {
      // Should not happen — document capture is Step 1. Defensive guard.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No document image found in session. '
              'Go back and capture the document first.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Update session state
    session.setSelfieImage(selfiePath);
    setState(() => _isVerifying = true);
    session.setFaceVerifying();

    // Call the face verification channel
    final result = await widget.faceService.verifyFaceFromPaths(
      selfieImagePath: selfiePath,
      documentImagePath: docPath,
    );

    if (!mounted) return;
    session.setFaceResult(result);
    setState(() => _isVerifying = false);
    Navigator.pushReplacementNamed(context, '/result');
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  final VoidCallback? onSkip;
  const _TopBar({this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back to document capture',
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Step 2 — Live Face Capture',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  'Rear camera • Photograph the traveler',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
          // Skip button — always accessible; face check is never mandatory
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(foregroundColor: Colors.amber.shade300),
            child: const Text(
              'Skip',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePreview extends StatelessWidget {
  final CameraController controller;
  const _LivePreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.previewSize!.height,
            height: controller.value.previewSize!.width,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

class _CapturedStill extends StatelessWidget {
  final String imagePath;
  const _CapturedStill({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(File(imagePath), fit: BoxFit.cover),
        Container(color: Colors.black26),
        const Center(
          child: Text(
            'Preview captured ↓ Confirm or Retake',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              shadows: [Shadow(color: Colors.black, blurRadius: 6)],
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingCamera extends StatelessWidget {
  const _LoadingCamera();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white54),
          SizedBox(height: 16),
          Text('Opening front camera…',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_rounded, size: 56, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapturePanel extends StatelessWidget {
  final VoidCallback? onCapture;
  final VoidCallback onSkip;
  const _CapturePanel({this.onCapture, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Capture shutter button
          GestureDetector(
            onTap: onCapture,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                color: onCapture != null
                    ? Colors.white.withOpacity(0.15)
                    : Colors.grey.withOpacity(0.15),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                color: onCapture != null ? Colors.white : Colors.grey,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            onCapture != null ? 'Tap to capture' : 'Camera unavailable',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 20),
          // Skip option — always available
          OutlinedButton.icon(
            onPressed: onSkip,
            icon: const Icon(Icons.skip_next_rounded, size: 18),
            label: const Text('Skip face verification'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.amber.shade200,
              side: BorderSide(color: Colors.amber.shade700, width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Skipping sets face check to NOT_RUN — OCR results are unaffected.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _ConfirmPanel extends StatelessWidget {
  final VoidCallback onRetake;
  final VoidCallback onConfirm;
  const _ConfirmPanel({required this.onRetake, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onRetake,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retake'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: onConfirm,
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('Confirm & verify face'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF238636),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifyingIndicator extends StatelessWidget {
  const _VerifyingIndicator();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      color: Colors.black87,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF58A6FF)),
          SizedBox(height: 16),
          Text(
            'Face verification running…',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          SizedBox(height: 4),
          Text(
            'On-device only • No network call',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
