import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fictional_screen/screening.dart';

void main() {
  // Hand-authored expectations, separate from the specimen generator.
  const header = 'SPECIMEN - NOT VALID FOR TRAVEL\nFICTIONAL PASSPORT ALPHA\n';
  final fixtures = <(String, String, ScreeningState)>[
    (
      'equal',
      '${header}DOCUMENT NUMBER: TEST123456\nREPEATED NUMBER: TEST123456',
      ScreeningState.noInconsistency,
    ),
    (
      'mismatch',
      '${header}DOCUMENT NUMBER: TEST123456\nREPEATED NUMBER: TEST123457',
      ScreeningState.reviewRequired,
    ),
    ('empty', '', ScreeningState.recapture),
    (
      'other layout',
      'A different fictional training document with clear text',
      ScreeningState.unsupported,
    ),
    (
      'missing repeat',
      '${header}DOCUMENT NUMBER: TEST123456',
      ScreeningState.recapture,
    ),
    (
      'ambiguous OCR',
      '${header}DOCUMENT NUMBER: TESTI23456\nREPEATED NUMBER: TEST123456',
      ScreeningState.recapture,
    ),
    (
      'duplicate',
      '${header}DOCUMENT NUMBER: TEST123456\nDOCUMENT NUMBER: TEST123456\nREPEATED NUMBER: TEST123456',
      ScreeningState.recapture,
    ),
    (
      'split lines',
      '${header}DOCUMENT NUMBER:\nTEST654321\nREPEATED NUMBER:\nTEST654321',
      ScreeningState.noInconsistency,
    ),
    (
      'case whitespace',
      '${header.toLowerCase()}document   number: test100001\nrepeated number: test100002',
      ScreeningState.reviewRequired,
    ),
    (
      'unlabelled specimen',
      'FICTIONAL PASSPORT ALPHA\nDOCUMENT NUMBER: TEST123456\nREPEATED NUMBER: TEST123456',
      ScreeningState.unsupported,
    ),
  ];
  for (final (name, text, expected) in fixtures) {
    test('independent fixture: $name', () {
      final result = screen(text);
      expect(result.state, expected);
      expect(result.toJson()['governmentVerification'], 'NOT_CONFIGURED');
      expect(result.toJson()['schemaVersion'], 1);
      expect(
        result.findings.length,
        expected == ScreeningState.reviewRequired ? 1 : 0,
      );
      if (expected == ScreeningState.reviewRequired) {
        expect(result.explanation, contains(result.fields['documentNumber']!));
        expect(result.explanation, contains(result.fields['repeatedNumber']!));
      }
    });
  }
  test('generated specimens match recorded expectations (text, not OCR)', () {
    final manifest =
        jsonDecode(File('specimens/manifest.json').readAsStringSync()) as Map;
    for (final specimen in manifest['specimens'] as List) {
      final result = screen(
        File('specimens/${specimen['id']}.txt').readAsStringSync(),
      );
      expect(
        result.state.code,
        specimen['expectedState'],
        reason: specimen['id'] as String,
      );
      expect(result.fields, specimen['expectedFields']);
    }
  });
}
