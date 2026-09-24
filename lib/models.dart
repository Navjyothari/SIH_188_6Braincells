import 'package:flutter/material.dart';

enum DangerRating {
  critical,
  high,
  elevated,
  low;

  String get label {
    switch (this) {
      case DangerRating.critical:
        return 'CRITICAL';
      case DangerRating.high:
        return 'HIGH';
      case DangerRating.elevated:
        return 'ELEVATED';
      case DangerRating.low:
        return 'LOW / CLEAN';
    }
  }

  Color get color {
    switch (this) {
      case DangerRating.critical:
        return const Color(0xFFEF4444); // Crimson Red
      case DangerRating.high:
        return const Color(0xFFF97316); // Bright Orange
      case DangerRating.elevated:
        return const Color(0xFFFBBF24); // Amber
      case DangerRating.low:
        return const Color(0xFF10B981); // Emerald Green
    }
  }

  Color get bgColor {
    switch (this) {
      case DangerRating.critical:
        return const Color(0x22EF4444);
      case DangerRating.high:
        return const Color(0x22F97316);
      case DangerRating.elevated:
        return const Color(0x22FBBF24);
      case DangerRating.low:
        return const Color(0x2210B981);
    }
  }
}

class DocumentRecord {
  final String docId;
  final String name;
  final String docNum;
  final String dobVisual;
  final String dobMrz;
  final String issueDate;
  final String expiryDate;
  final String sourcePort;
  final String destinationPort;
  final String corridor;
  final String group;
  final bool tampered;
  final List<String> tamperTypes;
  final String mrzLine1;
  final String mrzLine2;
  final String imagePath;

  DocumentRecord({
    required this.docId,
    required this.name,
    required this.docNum,
    required this.dobVisual,
    required this.dobMrz,
    required this.issueDate,
    required this.expiryDate,
    required this.sourcePort,
    required this.destinationPort,
    required this.corridor,
    required this.group,
    required this.tampered,
    required this.tamperTypes,
    required this.mrzLine1,
    required this.mrzLine2,
    required this.imagePath,
  });

  factory DocumentRecord.fromJson(Map<String, dynamic> json) {
    return DocumentRecord(
      docId: json['doc_id'] as String? ?? 'DOC_UNKNOWN',
      name: json['name'] as String? ?? 'UNKNOWN',
      docNum: json['doc_num'] as String? ?? '00000000',
      dobVisual: json['dob_visual'] as String? ?? json['dob'] as String? ?? '01-01-1980',
      dobMrz: json['dob_mrz'] as String? ?? '800101',
      issueDate: json['issue_date'] as String? ?? '01-01-2020',
      expiryDate: json['expiry_date'] as String? ?? '01-01-2030',
      sourcePort: json['source_port'] as String? ?? 'Sylas Port (North Sector)',
      destinationPort: json['destination_port'] as String? ?? 'Delhi ICP (Terminal 3)',
      corridor: json['corridor'] as String? ??
          '${json['source_port'] ?? 'Sylas Port (North Sector)'} -> ${json['destination_port'] ?? 'Delhi ICP (Terminal 3)'}',
      group: json['group'] as String? ?? 'Independent',
      tampered: json['tampered'] as bool? ?? false,
      tamperTypes: (json['tamper_types'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      mrzLine1: json['mrz_line1'] as String? ?? 'P<KLWUNKNOWN<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<',
      mrzLine2: json['mrz_line2'] as String? ?? '00000000<0KLW8001010M3001010<<<<<<<<<<<<<0<<',
      imagePath: json['image_path'] as String? ?? '',
    );
  }
}

class TamperFinding {
  final String category;
  final String detail;
  final DangerRating severity;
  final String technicalEvidence;

  TamperFinding({
    required this.category,
    required this.detail,
    required this.severity,
    required this.technicalEvidence,
  });
}

class TamperAnalysisResult {
  final DocumentRecord document;
  final bool isTampered;
  final double tamperScore; // 0.0 to 1.0
  final DangerRating dangerRating;
  final List<TamperFinding> findings;
  final String recommendation;
  final String primaryModusOperandi;

  TamperAnalysisResult({
    required this.document,
    required this.isTampered,
    required this.tamperScore,
    required this.dangerRating,
    required this.findings,
    required this.recommendation,
    required this.primaryModusOperandi,
  });
}

class CorridorRiskProfile {
  final String corridor;
  final String sourcePort;
  final String destinationPort;
  final int totalScreened;
  final int tamperedCount;
  final double tamperRate; // e.g. 0.35 (35%)
  final DangerRating dangerRating;
  final List<String> activeSyndicates;
  final String officerAdvisory;
  final List<DocumentRecord> recentDocuments;

  CorridorRiskProfile({
    required this.corridor,
    required this.sourcePort,
    required this.destinationPort,
    required this.totalScreened,
    required this.tamperedCount,
    required this.tamperRate,
    required this.dangerRating,
    required this.activeSyndicates,
    required this.officerAdvisory,
    required this.recentDocuments,
  });
}

class AuditTrailEntry {
  final int blockIndex;
  final DateTime timestamp;
  final String docId;
  final String passengerName;
  final String corridor;
  final DangerRating dangerRating;
  final String tamperSummary;
  final List<String> detectedAnomalies;
  final String actionTaken;
  final String previousHash;
  final String hash;

  AuditTrailEntry({
    required this.blockIndex,
    required this.timestamp,
    required this.docId,
    required this.passengerName,
    required this.corridor,
    required this.dangerRating,
    required this.tamperSummary,
    required this.detectedAnomalies,
    required this.actionTaken,
    required this.previousHash,
    required this.hash,
  });
}

class SyndicateCluster {
  final String clusterId;
  final String syndicateName;
  final String signatureSeal;
  final List<String> activeCorridors;
  final List<DocumentRecord> memberDocuments;
  final DangerRating threatLevel;
  final String technicalSummary;
  final List<String> commonModusOperandi;

  SyndicateCluster({
    required this.clusterId,
    required this.syndicateName,
    required this.signatureSeal,
    required this.activeCorridors,
    required this.memberDocuments,
    required this.threatLevel,
    required this.technicalSummary,
    required this.commonModusOperandi,
  });
}

// --- Backward Compatibility for Legacy Modules ---
class MatchedRegion {
  final double qX, qY, tX, tY;
  MatchedRegion({required this.qX, required this.qY, required this.tX, required this.tY});
  factory MatchedRegion.fromMap(Map<Object?, Object?> map) {
    return MatchedRegion(
      qX: (map['qX'] as num?)?.toDouble() ?? 0.0,
      qY: (map['qY'] as num?)?.toDouble() ?? 0.0,
      tX: (map['tX'] as num?)?.toDouble() ?? 0.0,
      tY: (map['tY'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PairwiseEdge {
  final String docId1;
  final String docId2;
  final double similarityScore;
  final String band;
  final List<MatchedRegion> matchedRegions;
  PairwiseEdge({
    required this.docId1,
    required this.docId2,
    required this.similarityScore,
    required this.band,
    required this.matchedRegions,
  });
  factory PairwiseEdge.fromMap(Map<Object?, Object?> map) {
    var regionsList = (map['matchedRegions'] as List<Object?>?) ?? [];
    return PairwiseEdge(
      docId1: map['docId1'] as String? ?? '',
      docId2: map['docId2'] as String? ?? '',
      similarityScore: (map['similarityScore'] as num?)?.toDouble() ?? 0.0,
      band: map['band'] as String? ?? 'NONE',
      matchedRegions: regionsList.map((r) => MatchedRegion.fromMap(r as Map<Object?, Object?>)).toList(),
    );
  }
}

class ClusterExplanation {
  final String clusterId;
  final List<String> memberIds;
  final String overallBand;
  final String summary;
  final List<PairwiseEdge> edges;
  ClusterExplanation({
    required this.clusterId,
    required this.memberIds,
    required this.overallBand,
    required this.summary,
    required this.edges,
  });
  factory ClusterExplanation.fromMap(Map<Object?, Object?> map) {
    var membersList = (map['memberIds'] as List<Object?>?) ?? [];
    var edgesList = (map['edges'] as List<Object?>?) ?? [];
    return ClusterExplanation(
      clusterId: map['clusterId'] as String? ?? '',
      memberIds: membersList.map((m) => m as String).toList(),
      overallBand: map['overallBand'] as String? ?? 'NONE',
      summary: map['summary'] as String? ?? '',
      edges: edgesList.map((e) => PairwiseEdge.fromMap(e as Map<Object?, Object?>)).toList(),
    );
  }
}
