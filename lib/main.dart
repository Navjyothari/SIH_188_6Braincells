import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'bridge.dart';
import 'capture_image.dart';
import 'screening.dart';

void main() => runApp(const ScreeningApp());

class ScreeningApp extends StatelessWidget {
  const ScreeningApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Fictional Screen',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff145e64)),
      useMaterial3: true,
    ),
    home: const CaptureScreen(),
  );
}

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});
  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final device = DeviceBridge();
  List<String> records = [];
  String? error;
  String? stage;
  Map<String, dynamic>? unsaved;
  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    try {
      final values = await device.list();
      if (mounted) {
        setState(() {
          records = values;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Saved evidence could not be listed. Retry; existing files have not been removed.',
        );
      }
    }
  }

  Future<void> capture() async {
    setState(() {
      stage = 'Opening camera';
      error = null;
    });
    try {
      final capture = await device.capture();
      if (capture == null) return;
      if (mounted) setState(() => stage = 'Reading text on this device');
      final bytes = capture['bytes'] as Uint8List;
      final rotation = capture['rotation'] as int;
      final ocr = await device.recognize(bytes, rotation);
      unsaved = {
        'envelopeVersion': 1,
        'capturedAt': DateTime.now().toUtc().toIso8601String(),
        'source': 'CAMERA',
        'synthetic': true,
        'original': {
          'mimeType': 'image/jpeg',
          'rotation': rotation,
          'base64': base64Encode(bytes),
        },
        'ocr': ocr,
        'result': screen(ocr['text'] as String).toJson(),
      };
      await savePending();
    } catch (failure) {
      if (mounted) {
        setState(() => error = captureFailureMessage(failure));
      }
    } finally {
      if (mounted) setState(() => stage = null);
    }
  }

  Future<void> savePending() async {
    final record = unsaved;
    if (record == null) return;
    if (mounted) setState(() => stage = 'Encrypting and saving evidence');
    try {
      final id = await device.save(jsonEncode(record));
      unsaved = null;
      await refresh();
      if (mounted) {
        setState(() => stage = null);
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => EvidenceScreen(id: id, record: record),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          stage = null;
          error =
              'Evidence is NOT SAVED. Free device storage and retry. The capture is held only until this app closes.';
        });
      }
    }
  }

  Future<void> open(String id) async {
    setState(() {
      stage = 'Opening encrypted evidence';
      error = null;
    });
    try {
      final record = jsonDecode(await device.load(id)) as Map<String, dynamic>;
      if (mounted) {
        setState(() => stage = null);
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => EvidenceScreen(id: id, record: record),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'This evidence could not be decrypted or verified. It may be damaged or its device key unavailable. The record has been retained.',
        );
      }
    } finally {
      if (mounted) setState(() => stage = null);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: stage == null,
    child: Scaffold(
      appBar: AppBar(title: const Text('Fictional Screen')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const TestBanner(),
            const SizedBox(height: 24),
            Text(
              'One card. One local check.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Use FICTIONAL PASSPORT ALPHA only. Include the full card, avoid glare, and keep both number fields sharp. All records are labelled synthetic training data.',
            ),
            const SizedBox(height: 20),
            if (stage != null) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
              Text(stage!),
            ],
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: stage != null || unsaved != null ? null : capture,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Capture fictional specimen'),
            ),
            if (unsaved != null)
              FilledButton(
                onPressed: stage == null ? savePending : null,
                child: const Text('Retry saving evidence'),
              ),
            const SizedBox(height: 12),
            const Text(
              'Government verification: NOT_CONFIGURED\nOnly number consistency is checked. No authenticity decision.',
            ),
            const Divider(height: 40),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Saved evidence',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: stage == null ? refresh : null,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (records.isEmpty) const Text('No saved evidence yet.'),
            for (final id in records)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_outline),
                title: const Text('Synthetic capture'),
                subtitle: Text(id),
                trailing: const Icon(Icons.chevron_right),
                onTap: stage == null ? () => open(id) : null,
              ),
          ],
        ),
      ),
    ),
  );
}

String captureFailureMessage(Object failure) {
  final code = failure is PlatformException
      ? failure.code
      : failure.runtimeType.toString();
  final guidance = switch (code) {
    'CAMERA_PERMISSION_DENIED' =>
      'Camera access was denied. Allow camera access in Android app settings and retry.',
    'CAMERA_FORMAT_UNSUPPORTED' =>
      'The camera returned an unsupported photo format.',
    'CAMERA_START_FAILED' =>
      'The camera could not start. Close other camera apps and retry.',
    'CAMERA_CAPTURE_FAILED' =>
      'The camera could not take the photo. Please retry.',
    'CAPTURE_TOO_LARGE' => 'The captured photo exceeds the supported size.',
    'IMAGE_DECODE_FAILED' =>
      'The captured photo could not be opened for text recognition.',
    _ when code.startsWith('OCR_') =>
      'The photo was captured, but offline text recognition failed. This is not a camera-permission error.',
    _ =>
      'The photo could not be processed. Please report the error code below.',
  };
  return '$guidance\nError code: $code\nNo completed record was saved.';
}

class TestBanner extends StatelessWidget {
  const TestBanner({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    color: const Color(0xffffe8ac),
    child: const Text(
      'TEST DATA • FICTIONAL SPECIMENS ONLY\nNOT VALID FOR TRAVEL',
      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
    ),
  );
}

class EvidenceScreen extends StatelessWidget {
  const EvidenceScreen({super.key, required this.id, required this.record});
  final String id;
  final Map<String, dynamic> record;
  @override
  Widget build(BuildContext context) {
    final result = record['result'] as Map<String, dynamic>;
    final original = record['original'] as Map<String, dynamic>;
    final fields = result['fields'] as Map<String, dynamic>;
    final bytes = base64Decode(original['base64'] as String);
    return Scaffold(
      appBar: AppBar(title: const Text('Result & evidence')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const TestBanner(),
          const SizedBox(height: 20),
          Text(
            (result['state'] as String).replaceAll('_', ' '),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(result['explanation'] as String),
          const SizedBox(height: 12),
          for (final field in fields.entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                field.key == 'documentNumber'
                    ? 'Document number'
                    : 'Repeated number',
              ),
              subtitle: SelectableText(field.value as String),
            ),
          const Divider(),
          const Text(
            'Encrypted evidence saved on this device',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '${record['capturedAt']}\nRecord: $id\nGovernment verification: ${result['governmentVerification']}\nPolicy: ${result['policyVersion']}',
          ),
          const SizedBox(height: 20),
          const Text('Original capture — pinch to inspect'),
          SizedBox(
            height: 320,
            child: InteractiveViewer(
              maxScale: 6,
              child: OriginalCaptureImage(
                bytes: bytes,
                rotation: original['rotation'] as int,
              ),
            ),
          ),
          ExpansionTile(
            title: const Text('Original OCR text'),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText((record['ocr'] as Map)['text'] as String),
              ),
            ],
          ),
          const Text(
            'Synthetic training record. A mismatch is a reason for review, not proof of fraud. No government service was contacted.',
          ),
        ],
      ),
    );
  }
}
