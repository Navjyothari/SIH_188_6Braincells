const layoutVersion = 'FICTIONAL PASSPORT ALPHA';
const policyVersion = 'number-consistency/1';

enum ScreeningState {
  recapture('RECAPTURE'),
  unsupported('UNSUPPORTED'),
  noInconsistency('NO_INCONSISTENCY_DETECTED'),
  reviewRequired('REVIEW_REQUIRED');

  const ScreeningState(this.code);
  final String code;
}

class ScreeningResult {
  const ScreeningResult(
    this.state,
    this.explanation,
    this.fields,
    this.findings,
  );
  final ScreeningState state;
  final String explanation;
  final Map<String, String> fields;
  final List<Map<String, String>> findings;
  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'policyVersion': policyVersion,
    'layout': layoutVersion,
    'synthetic': true,
    'state': state.code,
    'governmentVerification': 'NOT_CONFIGURED',
    'explanation': explanation,
    'fields': fields,
    'findings': findings,
  };
}

/// Deliberately narrow fictional parser; no real travel-document support.
ScreeningResult screen(String rawText) {
  final lines = rawText
      .toUpperCase()
      .split(RegExp(r'[\r\n]+'))
      .map((line) => line.trim().replaceAll(RegExp(r'\s+'), ' '))
      .where((line) => line.isNotEmpty)
      .toList();
  ScreeningResult stop(ScreeningState state, String message) =>
      ScreeningResult(state, message, const {}, const []);
  if (lines.join().length < 20) {
    return stop(
      ScreeningState.recapture,
      'Too little readable text. Retake with the entire card in focus.',
    );
  }
  if (!lines.contains(layoutVersion) ||
      !lines.contains('SPECIMEN - NOT VALID FOR TRAVEL')) {
    return stop(
      ScreeningState.unsupported,
      'Only the labelled fictional passport ALPHA training layout is supported.',
    );
  }
  final fields = <String, String>{};
  for (final entry in {
    'documentNumber': 'DOCUMENT NUMBER',
    'repeatedNumber': 'REPEATED NUMBER',
  }.entries) {
    final label = entry.value;
    final matches = <String>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line == label || line == '$label:') {
        matches.add(i + 1 < lines.length ? lines[i + 1] : '');
      } else if (line.startsWith('$label:')) {
        matches.add(line.substring(label.length + 1).trim());
      } else if (line.startsWith('$label ')) {
        matches.add(line.substring(label.length + 1).trim());
      }
    }
    // Duplicates and OCR ambiguity abstain; never repair characters silently.
    if (matches.length != 1 ||
        !RegExp(r'^TEST[0-9]{6}$').hasMatch(matches.single)) {
      return stop(
        ScreeningState.recapture,
        'The $label field is missing, duplicated, or unreadable. Retake the card; no consistency conclusion was made.',
      );
    }
    fields[entry.key] = matches.single;
  }
  if (fields['documentNumber'] != fields['repeatedNumber']) {
    final explanation =
        'Document number ${fields['documentNumber']} differs from repeated number ${fields['repeatedNumber']}. Review both printed fields; OCR error may also cause this mismatch.';
    return ScreeningResult(ScreeningState.reviewRequired, explanation, fields, [
      {
        'ruleId': 'DOCUMENT_NUMBER_REPEAT_MISMATCH',
        'explanation': explanation,
        'firstField': 'documentNumber',
        'secondField': 'repeatedNumber',
      },
    ]);
  }
  return ScreeningResult(
    ScreeningState.noInconsistency,
    'The two document numbers agree. This single check does not establish document authenticity or identity.',
    fields,
    const [],
  );
}
