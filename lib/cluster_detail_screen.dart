import 'package:flutter/material.dart';
import 'models.dart';

class ClusterDetailScreen extends StatelessWidget {
  final ClusterExplanation cluster;

  const ClusterDetailScreen({Key? key, required this.cluster}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cluster ${cluster.clusterId}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Members: ${cluster.memberIds.join(', ')}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              "Evidence (Pairwise matches):",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            ...cluster.edges.map((edge) => _buildEdgeCard(edge)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEdgeCard(PairwiseEdge edge) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Match: ${edge.docId1} <--> ${edge.docId2}", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("Band: ${edge.band}"),
            Text("Score: ${edge.similarityScore.toStringAsFixed(2)}"),
            const SizedBox(height: 16),
            // Mock visualization of side-by-side images with keypoint lines
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                border: Border.all(color: Colors.grey),
              ),
              child: Center(
                child: CustomPaint(
                  painter: MockMatchedRegionsPainter(edge.matchedRegions),
                  child: const SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: Center(child: Text("Side-by-side Image Visualization Mockup")),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text("Found ${edge.matchedRegions.length} matched visual regions."),
          ],
        ),
      ),
    );
  }
}

class MockMatchedRegionsPainter extends CustomPainter {
  final List<MatchedRegion> regions;

  MockMatchedRegionsPainter(this.regions);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw mock lines to represent bounding boxes / matched keypoints
    // Assuming left half is query image, right half is train image
    for (var region in regions) {
      // Mock coordinates mapping for illustration
      final qX = size.width * 0.25 + (region.qX % 50);
      final qY = size.height * 0.5 + (region.qY % 50);
      final tX = size.width * 0.75 + (region.tX % 50);
      final tY = size.height * 0.5 + (region.tY % 50);

      canvas.drawLine(Offset(qX, qY), Offset(tX, tY), paint);
      canvas.drawCircle(Offset(qX, qY), 4, paint);
      canvas.drawCircle(Offset(tX, tY), 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
