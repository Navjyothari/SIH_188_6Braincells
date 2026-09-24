import '../models.dart';
import 'tamper_analyzer.dart';

class CorridorEngine {
  /// Aggregates screened documents into Corridor Risk Profiles.
  static List<CorridorRiskProfile> computeCorridorProfiles(List<DocumentRecord> docs) {
    final Map<String, List<DocumentRecord>> grouped = {};

    for (final doc in docs) {
      grouped.putIfAbsent(doc.corridor, () => []).add(doc);
    }

    final profiles = <CorridorRiskProfile>[];

    grouped.forEach((corridor, docList) {
      int tamperedCount = 0;
      final syndicates = <String>{};

      for (final doc in docList) {
        final analysis = TamperAnalyzer.analyzeDocument(doc);
        if (analysis.isTampered) {
          tamperedCount++;
        }
        if (doc.group.startsWith("Kit_")) {
          syndicates.add(doc.group);
        }
      }

      final double rate = docList.isEmpty ? 0.0 : tamperedCount / docList.length;

      // Determine corridor danger rating
      DangerRating dangerRating;
      String advisory;

      final parts = corridor.split(' -> ');
      final source = parts.isNotEmpty ? parts[0] : 'Unknown Origin';
      final dest = parts.length > 1 ? parts[1] : 'Unknown Entry';

      if (rate >= 0.40 || tamperedCount >= 5) {
        dangerRating = DangerRating.critical;
        advisory =
            "🚨 CRITICAL ALERT: Extremely high fraud prevalence (${(rate * 100).toStringAsFixed(1)}%) along this corridor! Border guards at $dest MUST pay heightened scrutiny to all passengers originating from $source. Enforce 100% secondary screening.";
      } else if (rate >= 0.20 || tamperedCount >= 2) {
        dangerRating = DangerRating.high;
        advisory =
            "⚠️ ELEVATED THREAT: Multiple tampered credentials ($tamperedCount of ${docList.length}) intercepted arriving at $dest from $source. Active syndicate artifacts detected: ${syndicates.join(', ')}.";
      } else if (tamperedCount > 0) {
        dangerRating = DangerRating.elevated;
        advisory =
            "⚡ CAUTION: Isolated suspicious document activity recorded on this route. Routine scrutiny advised for travelers departing $source.";
      } else {
        dangerRating = DangerRating.low;
        advisory =
            "✅ NORMAL FLOW: No fraudulent or altered documents recorded on this corridor to date. Standard automated e-Gate processing permitted.";
      }

      profiles.add(
        CorridorRiskProfile(
          corridor: corridor,
          sourcePort: source,
          destinationPort: dest,
          totalScreened: docList.length,
          tamperedCount: tamperedCount,
          tamperRate: rate,
          dangerRating: dangerRating,
          activeSyndicates: syndicates.toList(),
          officerAdvisory: advisory,
          recentDocuments: docList,
        ),
      );
    });

    // Sort by highest risk first
    profiles.sort((a, b) {
      if (b.dangerRating != a.dangerRating) {
        return b.dangerRating.index.compareTo(a.dangerRating.index);
      }
      return b.tamperRate.compareTo(a.tamperRate);
    });

    return profiles;
  }
}
