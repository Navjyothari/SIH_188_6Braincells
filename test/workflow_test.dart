import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fictional_screen/bridge.dart';
import 'package:fictional_screen/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final original = File('specimens/01-altered.png').readAsBytesSync();
  final text = File('specimens/01-altered.txt').readAsStringSync();
  final records = <String, String>{};
  var failSave = false;
  var cancel = false;
  String? ocrError;
  setUp(() {
    records.clear();
    failSave = false;
    cancel = false;
    ocrError = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DeviceBridge.channel, (call) async {
          switch (call.method) {
            case 'capture':
              return cancel ? null : {'bytes': original, 'rotation': 0};
            case 'recognize':
              if (ocrError != null) throw PlatformException(code: ocrError!);
              return {'text': text, 'blocks': <dynamic>[]};
            case 'save':
              if (failSave) throw PlatformException(code: 'STORAGE_FAILED');
              records['test-record'] =
                  (call.arguments as Map)['envelope'] as String;
              return 'test-record';
            case 'list':
              return records.keys.toList();
            case 'load':
              return records[(call.arguments as Map)['id']];
          }
          throw MissingPluginException();
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DeviceBridge.channel, null),
  );

  testWidgets(
    'capture explains mismatch and reopens identical saved evidence',
    (tester) async {
      await tester.pumpWidget(const ScreeningApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Capture fictional specimen'));
      await tester.pumpAndSettle();
      expect(find.text('REVIEW REQUIRED'), findsOneWidget);
      final envelope = jsonDecode(records.values.single) as Map;
      expect(base64Decode(envelope['original']['base64'] as String), original);
      expect(envelope['result']['governmentVerification'], 'NOT_CONFIGURED');
      // Recreate the Flutter app, preserving only the mocked native disk.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const ScreeningApp());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Synthetic capture'));
      await tester.tap(find.text('Synthetic capture'));
      await tester.pumpAndSettle();
      expect(find.text('REVIEW REQUIRED'), findsOneWidget);
      expect(records.length, 1);
    },
  );
  testWidgets('failed save stays unsaved and retry preserves original', (
    tester,
  ) async {
    failSave = true;
    await tester.pumpWidget(const ScreeningApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Capture fictional specimen'));
    await tester.pumpAndSettle();
    expect(records, isEmpty);
    expect(find.textContaining('Evidence is NOT SAVED.'), findsOneWidget);
    expect(find.text('Result & evidence'), findsNothing);
    failSave = false;
    await tester.ensureVisible(find.text('Retry saving evidence'));
    await tester.tap(find.text('Retry saving evidence'));
    await tester.pumpAndSettle();
    expect(find.text('REVIEW REQUIRED'), findsOneWidget);
    expect(records.length, 1);
  });
  testWidgets('camera cancellation creates no record', (tester) async {
    cancel = true;
    await tester.pumpWidget(const ScreeningApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Capture fictional specimen'));
    await tester.pumpAndSettle();
    expect(records, isEmpty);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets(
    'OCR failure reports its code without blaming camera permission',
    (tester) async {
      ocrError = 'OCR_SecurityException';
      await tester.pumpWidget(const ScreeningApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Capture fictional specimen'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Error code: OCR_SecurityException'),
        findsOneWidget,
      );
      expect(find.textContaining('Allow camera access'), findsNothing);
      expect(records, isEmpty);
    },
  );
}
