# Document Similarity Clustering Module

This module provides offline, on-device clustering of document records to flag potentially related documents for human review. It uses classical Computer Vision (ORB features) to match visual elements and a Connected Components graph algorithm to form clusters.

## Caveats for Legal/Judicial Use

**CRITICAL:** The output of this module MUST NOT be presented as automated proof of criminal activity, forgery, or organized fraud rings. 
Any judicial or investigative material referencing this module must include the following caveats:

1. **Not a Deterministic Match:** A high similarity band indicates shared visual or structural elements, not shared attribution. Documents may be similar due to legitimate shared templates, shared printing hardware, or shared camera artifacts.
2. **"Flagged for Review" Only:** This module acts merely as a sorting mechanism to surface documents for human forensic review. It does not output a "risk score" or a "fraud percentage".
3. **Algorithm Limitations:** The Connected Components algorithm can "chain" weakly connected documents together into a single large cluster. A document's membership in a cluster only implies a similarity to *at least one other document* in that cluster, not necessarily to all of them.

## Methodology

### Feature Extraction
We use **OpenCV with ORB (Oriented FAST and Rotated BRIEF)**. 
- ORB extracts keypoints (interesting visual corners/edges) and computes descriptors.
- It is highly performant on mobile devices and fully offline.
- Most importantly, it is **explainable**: we can extract the exact (x, y) coordinates of matching keypoints to draw bounding boxes, showing the human reviewer exactly *what* matched.

### Similarity Graph & Clustering
- Each document is a node.
- An edge is drawn between two nodes if the number of matching ORB keypoints (using Hamming distance) exceeds a configurable `similarityThreshold`.
- Clusters are formed using the **Connected Components** algorithm (Union-Find). 
- The similarities are bucketed into qualitative bands: Low, Medium, High.

## Known Failure Modes / False Positives
- **Blank/Standard Forms:** Two entirely legitimate, correctly filled forms of the same template will exhibit high similarity.
- **Lighting/Texture Artifacts:** If multiple documents were photographed on the same highly textured wooden desk under the same lighting, the background keypoints might match heavily, falsely linking the documents.
- **Low Resolution:** Very blurry images will produce few ORB keypoints, potentially resulting in false negatives (failing to cluster actually related documents).

## Configuration
Thresholds and weightings can be adjusted in the `SimilarityConfig.kt` or passed from the Dart UI to tune the sensitivity.
