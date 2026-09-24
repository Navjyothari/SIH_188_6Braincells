import 'package:flutter/material.dart';
import 'models.dart';
import 'cluster_detail_screen.dart';

class SimilarityReviewScreen extends StatelessWidget {
  final List<ClusterExplanation> clusters;

  const SimilarityReviewScreen({Key? key, required this.clusters}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Similarity Review'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.amber.shade100,
            child: const Text(
              "Note: These documents share visual similarities and may share a common source — or the similarity may be coincidental (shared legitimate template, printer, or camera). Flagged for review.",
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: clusters.isEmpty
                ? const Center(child: Text("No similar documents found."))
                : ListView.builder(
                    itemCount: clusters.length,
                    itemBuilder: (context, index) {
                      final cluster = clusters[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: ListTile(
                          title: Text('Cluster: ${cluster.clusterId} (${cluster.memberIds.length} documents)'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cluster.summary),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Text('Similarity: '),
                                  _buildBandBadge(cluster.overallBand),
                                ],
                              )
                            ],
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ClusterDetailScreen(cluster: cluster),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBandBadge(String band) {
    Color color;
    switch (band) {
      case 'HIGH':
        color = Colors.red;
        break;
      case 'MEDIUM':
        color = Colors.orange;
        break;
      case 'LOW':
        color = Colors.yellow.shade700;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        band,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
