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
  final abstentionCases = <String, String>{
    'missing document': '${header}REPEATED NUMBER: TEST123456',
    'repeat OCR ambiguity':
        '${header}DOCUMENT NUMBER: TEST123456\nREPEATED NUMBER: TEST12345O',
    'conflicting repeated fields':
        '${header}DOCUMENT NUMBER: TEST123456\nREPEATED NUMBER: TEST123456\nREPEATED NUMBER: TEST123457',
    'identical repeated fields duplicated':
        '${header}DOCUMENT NUMBER: TEST123456\nREPEATED NUMBER: TEST123456\nREPEATED NUMBER: TEST123456',
    'both equally malformed':
        '${header}DOCUMENT NUMBER: TEST12345\nREPEATED NUMBER: TEST12345',
    'extra digit':
        '${header}DOCUMENT NUMBER: TEST1234567\nREPEATED NUMBER: TEST123456',
    'trailing OCR text':
        '${header}DOCUMENT NUMBER: TEST123456 EXTRA\nREPEATED NUMBER: TEST123456',
    'label at end without value':
        '${header}DOCUMENT NUMBER: TEST123456\nREPEATED NUMBER:',
  };
  for (final entry in abstentionCases.entries) {
    test('no conclusion for ${entry.key}', () {
      final result = screen(entry.value);
      expect(result.state, ScreeningState.recapture);
      expect(result.fields, isEmpty);
      expect(result.findings, isEmpty);
      expect(result.explanation, contains('no consistency conclusion'));
      expect(result.toJson()['governmentVerification'], 'NOT_CONFIGURED');
    });
  }
  test('unsupported layout takes precedence over a readable mismatch', () {
    final result = screen(
      'SPECIMEN - NOT VALID FOR TRAVEL\nFICTIONAL PASSPORT BETA\n'
      'DOCUMENT NUMBER: TEST123456\nREPEATED NUMBER: TEST123457',
    );
    expect(result.state, ScreeningState.unsupported);
    expect(result.fields, isEmpty);
    expect(result.findings, isEmpty);
  });
  test('matching numbers explicitly disclaim authenticity and identity', () {
    final result = screen(
      '${header}DOCUMENT NUMBER TEST123456\nREPEATED NUMBER TEST123456',
    );
    expect(result.state, ScreeningState.noInconsistency);
    expect(
      result.explanation,
      contains('does not establish document authenticity or identity'),
    );
  });
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
