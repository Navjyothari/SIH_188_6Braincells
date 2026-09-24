import 'dart:io';
import 'package:flutter/material.dart';
import '../models.dart';
import '../services/tamper_analyzer.dart';

class DocumentInspectorModal extends StatelessWidget {
  final DocumentRecord document;

  const DocumentInspectorModal({Key? key, required this.document}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final analysis = TamperAnalyzer.analyzeDocument(document);
    final danger = analysis.dangerRating;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Handle
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header: Doc ID & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.docId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Passenger: ${document.name}",
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: danger.bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: danger.color),
                  ),
                  child: Text(
                    danger.label,
                    style: TextStyle(
                      color: danger.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Transit Corridor Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF162032),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.compare_arrows_rounded, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "TRANSIT ROUTE / CORRIDOR",
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          document.corridor,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Specimen Image Preview (if file exists)
            _buildSpecimenPreview(document),
            const SizedBox(height: 16),

            // Forensic & Tamper AI Model Findings Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: danger == DangerRating.critical || danger == DangerRating.high
                    ? const Color(0xFF261214)
                    : const Color(0xFF13221C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: danger.color.withOpacity(0.6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        analysis.isTampered ? Icons.security_update_warning_rounded : Icons.verified_user_rounded,
                        color: danger.color,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        analysis.isTampered ? "TAMPERING DETECTED BY FORENSIC MODEL" : "PASSPORT CREDENTIAL INTEGRITY VERIFIED",
                        style: TextStyle(
                          color: danger.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    analysis.recommendation,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  if (analysis.findings.isNotEmpty) ...[
                    const Divider(color: Color(0xFF475569), height: 20),
                    const Text(
                      "Detected Irregularities & Evidence:",
                      style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    ...analysis.findings.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("• ", style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(
                                  "${f.category}: ${f.technicalEvidence}",
                                  style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Side-by-side OCR Visual Zone vs MRZ Machine-Readable Zone
            const Text(
              "OCR Optical Inspection vs Machine-Readable Zone (MRZ)",
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF162032),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                children: [
                  _buildComparisonRow(
                    "Document Number",
                    document.docNum,
                    document.mrzLine2.length >= 9 ? document.mrzLine2.substring(0, 9).replaceAll('<', '') : 'N/A',
                    false,
                  ),
                  const Divider(color: Color(0xFF1E293B), height: 1),
                  _buildComparisonRow(
                    "Date of Birth (DOB)",
                    document.dobVisual,
                    document.dobMrz,
                    _isDobMismatched(document.dobVisual, document.dobMrz),
                  ),
                  const Divider(color: Color(0xFF1E293B), height: 1),
                  _buildComparisonRow(
                    "Expiration Date",
                    document.expiryDate,
                    document.mrzLine2.length >= 27 ? document.mrzLine2.substring(21, 27) : 'N/A',
                    document.tamperTypes.contains("EXPIRY_TAMPER"),
                  ),
                  const Divider(color: Color(0xFF1E293B), height: 1),
                  _buildComparisonRow(
                    "Syndicate Toolmark Seal",
                    document.group,
                    document.group.startsWith("Kit_") ? "CLONED SEAL DETECTED" : "STANDARD / NONE",
                    document.group.startsWith("Kit_"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Raw MRZ Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF080C14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "RAW ICAO 9303 MRZ STREAM",
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 10, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    document.mrzLine1,
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    document.mrzLine2,
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Close Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  foregroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("CLOSE INSPECTION", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecimenPreview(DocumentRecord doc) {
    bool hasLocalImage = false;
    File? imgFile;
    if (doc.imagePath.isNotEmpty) {
      imgFile = File(doc.imagePath);
      if (imgFile.existsSync()) {
        hasLocalImage = true;
      }
    }

    if (hasLocalImage && imgFile != null) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.file(imgFile, fit: BoxFit.cover),
      );
    }

    // High fidelity rendered specimen box
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF475569)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.person, size: 40, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "REPUBLIC OF KELWANIA // PASSPORT SPECIMEN",
                  style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  doc.name,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Doc No: ${doc.docNum}  •  DOB: ${doc.dobVisual}",
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
                Text(
                  "Route: ${doc.corridor}",
                  style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, String visualVal, String mrzVal, bool isMismatch) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Visual: $visualVal",
                  style: TextStyle(
                    color: isMismatch ? const Color(0xFFEF4444) : Colors.white,
                    fontWeight: isMismatch ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
                Text(
                  "MRZ: $mrzVal",
                  style: TextStyle(
                    color: isMismatch ? const Color(0xFFF97316) : const Color(0xFF64748B),
                    fontWeight: isMismatch ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isMismatch)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0x33EF4444),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "CONFLICT",
                style: TextStyle(color: Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  bool _isDobMismatched(String visual, String mrz) {
    try {
      final parts = visual.split('-');
      if (parts.length == 3) {
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2].substring(parts[2].length - 2);
        return '$year$month$day' != mrz;
      }
    } catch (_) {}
    return false;
  }
}
