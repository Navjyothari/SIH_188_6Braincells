import 'package:flutter/services.dart';
import 'models.dart';

class SimilarityApi {
  static const MethodChannel _channel = MethodChannel('com.example.sih/similarity');

  /// Runs the clustering algorithm on a list of document records.
  /// Expects a list of maps containing 'id' and 'imagePath'.
  static Future<List<ClusterExplanation>> runClustering(List<Map<String, String>> documents) async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('runClustering', documents);
      return result.map((dynamic item) {
        return ClusterExplanation.fromMap(item as Map<Object?, Object?>);
      }).toList();
    } on PlatformException catch (e) {
      throw Exception("Failed to run clustering: '${e.message}'.");
    }
  }
}
