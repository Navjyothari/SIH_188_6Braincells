import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models.dart';

class DocumentLoader {
  static Future<List<DocumentRecord>> loadDocuments() async {
    // 1. Attempt to load live from the output directory of the synthetic doc generator
    try {
      final possiblePaths = [
        'tools/document_generator/output/synthetic_docs/ground_truth.json',
        '../tools/document_generator/output/synthetic_docs/ground_truth.json',
        'output/synthetic_docs/ground_truth.json',
        'C:/Users/Unknown/Desktop/sih/tools/document_generator/output/synthetic_docs/ground_truth.json',
      ];

      for (final path in possiblePaths) {
        final file = File(path);
        if (await file.exists()) {
          final content = await file.readAsString();
          final List<dynamic> data = jsonDecode(content) as List<dynamic>;
          if (data.isNotEmpty) {
            debugPrint('Loaded ${data.length} documents from $path');
            return data
                .map((e) => DocumentRecord.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
      }
    } catch (e) {
      debugPrint('Live document load failed: $e');
    }

    // 2. Fallback in-memory corpus if file not yet accessible or running in web
    return _getFallbackCorpus();
  }

  static List<DocumentRecord> _getFallbackCorpus() {
    return [
      DocumentRecord(
        docId: "DOC_0006",
        name: "Korvax Thalira",
        docNum: "38475525",
        dobVisual: "21-01-1986",
        dobMrz: "860121",
        issueDate: "12-07-2018",
        expiryDate: "16-10-2027",
        sourcePort: "Kelwan Outpost",
        destinationPort: "Attari Land Checkpoint",
        corridor: "Kelwan Outpost -> Attari Land Checkpoint",
        group: "Kit_C",
        tampered: true,
        tamperTypes: ["MRZ_CHECKSUM_FAILURE", "FORGERY_RING_Kit_C"],
        mrzLine1: "P<KLWKorvax<<Thalira<<<<<<<<<<<<<<<<<<<<<<<<",
        mrzLine2: "38475525<0KLW8601218M2710165<<<<<<<<<<<<<7<<",
        imagePath: "tools/document_generator/output/synthetic_docs/DOC_0006.jpg",
      ),
      DocumentRecord(
        docId: "DOC_0012",
        name: "Sylas Tarik",
        docNum: "49219384",
        dobVisual: "01-01-2005",
        dobMrz: "760514",
        issueDate: "10-03-2019",
        expiryDate: "20-03-2029",
        sourcePort: "Sylas Port (North Sector)",
        destinationPort: "Delhi ICP (Terminal 3)",
        corridor: "Sylas Port (North Sector) -> Delhi ICP (Terminal 3)",
        group: "Kit_A",
        tampered: true,
        tamperTypes: ["DOB_MISMATCH", "FORGERY_RING_Kit_A", "CLONED_SYNDICATE_SEAL"],
        mrzLine1: "P<KLWSylas<<Tarik<<<<<<<<<<<<<<<<<<<<<<<<<<<",
        mrzLine2: "49219384<3KLW7605142M2903208<<<<<<<<<<<<<4<<",
        imagePath: "tools/document_generator/output/synthetic_docs/DOC_0012.jpg",
      ),
      DocumentRecord(
        docId: "DOC_0019",
        name: "Windrider Garrick",
        docNum: "88204910",
        dobVisual: "14-08-1982",
        dobMrz: "820814",
        issueDate: "05-05-2016",
        expiryDate: "12-05-2021",
        sourcePort: "Vortigan Border Crossing",
        destinationPort: "Mumbai Sea Gate 2",
        corridor: "Vortigan Border Crossing -> Mumbai Sea Gate 2",
        group: "Kit_B",
        tampered: true,
        tamperTypes: ["EXPIRY_TAMPER", "FORGERY_RING_Kit_B"],
        mrzLine1: "P<KLWWindrider<<Garrick<<<<<<<<<<<<<<<<<<<<<",
        mrzLine2: "88204910<9KLW8208146M2105125<<<<<<<<<<<<<1<<",
        imagePath: "tools/document_generator/output/synthetic_docs/DOC_0019.jpg",
      ),
      DocumentRecord(
        docId: "DOC_0025",
        name: "Cobalt Elara",
        docNum: "66190283",
        dobVisual: "19-11-1991",
        dobMrz: "911119",
        issueDate: "12-11-2020",
        expiryDate: "12-11-2030",
        sourcePort: "Sylas Port (North Sector)",
        destinationPort: "Delhi ICP (Terminal 3)",
        corridor: "Sylas Port (North Sector) -> Delhi ICP (Terminal 3)",
        group: "Kit_A",
        tampered: true,
        tamperTypes: ["FORGERY_RING_Kit_A", "CLONED_SYNDICATE_SEAL"],
        mrzLine1: "P<KLWCobalt<<Elara<<<<<<<<<<<<<<<<<<<<<<<<<<",
        mrzLine2: "66190283<7KLW9111191M3011124<<<<<<<<<<<<<2<<",
        imagePath: "tools/document_generator/output/synthetic_docs/DOC_0025.jpg",
      ),
      DocumentRecord(
        docId: "DOC_0030",
        name: "Thorne Marlex",
        docNum: "99120485",
        dobVisual: "04-09-1988",
        dobMrz: "880904",
        issueDate: "19-08-2021",
        expiryDate: "19-08-2031",
        sourcePort: "Zorba Transit Hub",
        destinationPort: "Kolkata Port Entry",
        corridor: "Zorba Transit Hub -> Kolkata Port Entry",
        group: "Independent",
        tampered: false,
        tamperTypes: [],
        mrzLine1: "P<KLWThorne<<Marlex<<<<<<<<<<<<<<<<<<<<<<<<<",
        mrzLine2: "99120485<1KLW8809045M3108197<<<<<<<<<<<<<8<<",
        imagePath: "tools/document_generator/output/synthetic_docs/DOC_0030.jpg",
      ),
    ];
  }
}
