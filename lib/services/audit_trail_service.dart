import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models.dart';
import 'tamper_analyzer.dart';

class AuditTrailService {
  static final List<AuditTrailEntry> _ledger = [];

  /// Builds a verifiable tamper-evident hash chain from the screened documents.
  static List<AuditTrailEntry> generateAuditTrail(List<DocumentRecord> docs) {
    _ledger.clear();
    String previousHash = "0000000000000000000000000000000000000000000000000000000000000000"; // Genesis block

    int blockIndex = 1;
    final baseTime = DateTime.now().subtract(Duration(hours: docs.length ~/ 2));

    for (int i = 0; i < docs.length; i++) {
      final doc = docs[i];
      final analysis = TamperAnalyzer.analyzeDocument(doc);

      // We log all tampered documents, plus sample verified documents for full auditability
      if (analysis.isTampered || i % 8 == 0) {
        final timestamp = baseTime.add(Duration(minutes: i * 7));
        final anomalies = analysis.findings.map((f) => "${f.category}: ${f.detail}").toList();
        final action = analysis.isTampered ? "OFFICER_REFERRED / FLAGGED" : "SCREENING_CLEARED";
        final summary = analysis.isTampered
            ? "Tampering Detected [${analysis.dangerRating.label}]: ${analysis.findings.firstOrNull?.category ?? 'Inconsistency'}"
            : "Credential verified against ICAO 9303 standards";

        // Compute SHA-256 Block Hash: sha256(index + timestamp + docId + corridor + anomalies + prevHash)
        final rawBlockData = "$blockIndex|${timestamp.toIso8601String()}|${doc.docId}|${doc.corridor}|${anomalies.join(';')}|$previousHash";
        final currentHash = sha256.convert(utf8.encode(rawBlockData)).toString();

        final entry = AuditTrailEntry(
          blockIndex: blockIndex,
          timestamp: timestamp,
          docId: doc.docId,
          passengerName: doc.name,
          corridor: doc.corridor,
          dangerRating: analysis.dangerRating,
          tamperSummary: summary,
          detectedAnomalies: anomalies,
          actionTaken: action,
          previousHash: previousHash,
          hash: currentHash,
        );

        _ledger.add(entry);
        previousHash = currentHash;
        blockIndex++;
      }
    }

    return List.unmodifiable(_ledger);
  }

  /// Verifies the cryptographic chain integrity.
  /// Returns true if every block's hash correctly anchors to the previous block's hash.
  static bool verifyChainIntegrity() {
    if (_ledger.isEmpty) return true;

    for (int i = 0; i < _ledger.length; i++) {
      final current = _ledger[i];
      final expectedPrevHash = (i == 0)
          ? "0000000000000000000000000000000000000000000000000000000000000000"
          : _ledger[i - 1].hash;

      if (current.previousHash != expectedPrevHash) {
        return false;
      }

      // Re-hash block
      final rawBlockData =
          "${current.blockIndex}|${current.timestamp.toIso8601String()}|${current.docId}|${current.corridor}|${current.detectedAnomalies.join(';')}|${current.previousHash}";
      final computedHash = sha256.convert(utf8.encode(rawBlockData)).toString();

      if (computedHash != current.hash) {
        return false;
      }
    }

    return true;
  }
}
