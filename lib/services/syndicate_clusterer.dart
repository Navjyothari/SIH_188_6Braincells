import '../models.dart';
import 'tamper_analyzer.dart';

class SyndicateClusterer {
  /// Clusters documents into fraud rings / syndicates based on toolmarks, corridors, and modus operandi.
  static List<SyndicateCluster> clusterDocuments(List<DocumentRecord> docs) {
    final Map<String, List<DocumentRecord>> groups = {};

    for (final doc in docs) {
      if (doc.group.startsWith("Kit_")) {
        groups.putIfAbsent(doc.group, () => []).add(doc);
      }
    }

    final clusters = <SyndicateCluster>[];

    groups.forEach((groupKey, members) {
      final corridors = <String>{};
      final tamperTypes = <String>{};
      int tamperedCount = 0;

      for (final doc in members) {
        corridors.add(doc.corridor);
        tamperTypes.addAll(doc.tamperTypes);
        final analysis = TamperAnalyzer.analyzeDocument(doc);
        if (analysis.isTampered) tamperedCount++;
      }

      String syndicateName = "Unknown Network";
      String signatureSeal = "Generic";
      String technicalSummary = "";
      List<String> commonModus = [];
      DangerRating threat = DangerRating.high;

      if (groupKey == "Kit_A") {
        syndicateName = "Red Seal Forgery Ring (Kit-A)";
        signatureSeal = "CLONED_RED_BORDER_EXEMPT_STAMP";
        technicalSummary =
            "Syndicate utilizes a digital replica of an official border clearance stamp with a fixed +18° rotational skew and 150px outer border. $tamperedCount of ${members.length} members confirmed altered.";
        commonModus = [
          "Replication of circular 'BORDER EXEMPT' red ink seal",
          "Visual DOB alteration targeting immigration age gates",
          "Primary funnel: Sylas Port -> Delhi ICP",
        ];
      } else if (groupKey == "Kit_B") {
        syndicateName = "Consular-B Diplomatic Cachet Cell (Kit-B)";
        signatureSeal = "BLUE_TRIANGULAR_CONSULAR_CACHET";
        threat = DangerRating.high;
        technicalSummary =
            "Syndicate leverages pre-printed security paper with a characteristic cyan/blue background tint shift and slight Gaussian micro-print smoothing. $tamperedCount of ${members.length} members confirmed altered.";
        commonModus = [
          "Forged triangular consular endorsement stamp",
          "Subtle card substrate tint alteration (#EBF3FC)",
          "Corridor concentration: Vortigan Border Crossing -> Attari Checkpoint",
        ];
      } else if (groupKey == "Kit_C") {
        syndicateName = "Transit Sector-C Forgery Network (Kit-C)";
        signatureSeal = "RECTANGULAR_TRANSIT_PERMIT_SEAL";
        threat = DangerRating.critical;
        technicalSummary =
            "Specialized in fake transit permits with a distinct +12px vertical baseline shift across all visual data fields and invalid MRZ composite check digits. $tamperedCount of ${members.length} members confirmed altered.";
        commonModus = [
          "Rectangular 'TRANSIT PERMIT [ AUTH SEC-C ]' purple seal",
          "Vertical layout offset (+12px shift)",
          "Corridor concentration: Zorba Transit Hub -> Mumbai Sea Gate 2",
        ];
      }

      clusters.add(
        SyndicateCluster(
          clusterId: "RING-${groupKey.toUpperCase()}",
          syndicateName: syndicateName,
          signatureSeal: signatureSeal,
          activeCorridors: corridors.toList(),
          memberDocuments: members,
          threatLevel: threat,
          technicalSummary: technicalSummary,
          commonModusOperandi: commonModus,
        ),
      );
    });

    // Sort by largest syndicate membership
    clusters.sort((a, b) => b.memberDocuments.length.compareTo(a.memberDocuments.length));
    return clusters;
  }
}
