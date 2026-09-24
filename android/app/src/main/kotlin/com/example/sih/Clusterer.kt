package com.example.sih

data class ClusterExplanation(
    val clusterId: String,
    val memberIds: List<String>,
    val edges: List<PairwiseComparisonResult>,
    val overallBand: SimilarityBand,
    val summary: String
)

class Clusterer {

    /**
     * Builds a similarity graph and extracts connected components.
     */
    fun clusterDocuments(comparisons: List<PairwiseComparisonResult>): List<ClusterExplanation> {
        // Filter out NONE similarities to form the graph edges
        val edges = comparisons.filter { it.band != SimilarityBand.NONE }
        
        // Build adjacency list for undirected graph
        val adjList = mutableMapOf<String, MutableList<String>>()
        val edgeMap = mutableMapOf<Pair<String, String>, PairwiseComparisonResult>()
        
        for (edge in edges) {
            adjList.computeIfAbsent(edge.docId1) { mutableListOf() }.add(edge.docId2)
            adjList.computeIfAbsent(edge.docId2) { mutableListOf() }.add(edge.docId1)
            
            // Store undirected edge data
            val key = getEdgeKey(edge.docId1, edge.docId2)
            edgeMap[key] = edge
        }
        
        val visited = mutableSetOf<String>()
        val clusters = mutableListOf<ClusterExplanation>()
        var clusterCounter = 1
        
        for (node in adjList.keys) {
            if (node !in visited) {
                // BFS to find connected component
                val component = mutableListOf<String>()
                val queue = ArrayDeque<String>()
                
                queue.add(node)
                visited.add(node)
                
                while (queue.isNotEmpty()) {
                    val current = queue.removeFirst()
                    component.add(current)
                    
                    for (neighbor in adjList[current] ?: emptyList()) {
                        if (neighbor !in visited) {
                            visited.add(neighbor)
                            queue.add(neighbor)
                        }
                    }
                }
                
                // Only consider clusters of size > 1
                if (component.size > 1) {
                    val componentEdges = extractEdgesForComponent(component, edgeMap)
                    
                    val explanation = ClusterExplanation(
                        clusterId = "Cluster-$clusterCounter",
                        memberIds = component,
                        edges = componentEdges,
                        overallBand = determineOverallBand(componentEdges),
                        summary = generateClusterSummary(componentEdges)
                    )
                    clusters.add(explanation)
                    clusterCounter++
                }
            }
        }
        
        return clusters
    }
    
    private fun getEdgeKey(id1: String, id2: String): Pair<String, String> {
        return if (id1 < id2) Pair(id1, id2) else Pair(id2, id1)
    }
    
    private fun extractEdgesForComponent(
        component: List<String>, 
        edgeMap: Map<Pair<String, String>, PairwiseComparisonResult>
    ): List<PairwiseComparisonResult> {
        val edges = mutableListOf<PairwiseComparisonResult>()
        for (i in component.indices) {
            for (j in i + 1 until component.size) {
                val key = getEdgeKey(component[i], component[j])
                edgeMap[key]?.let { edges.add(it) }
            }
        }
        return edges
    }
    
    private fun determineOverallBand(edges: List<PairwiseComparisonResult>): SimilarityBand {
        if (edges.isEmpty()) return SimilarityBand.NONE
        // Return the highest band found in the cluster to prioritize reviewer attention
        return when {
            edges.any { it.band == SimilarityBand.HIGH } -> SimilarityBand.HIGH
            edges.any { it.band == SimilarityBand.MEDIUM } -> SimilarityBand.MEDIUM
            else -> SimilarityBand.LOW
        }
    }
    
    private fun generateClusterSummary(edges: List<PairwiseComparisonResult>): String {
        val totalMatches = edges.sumOf { it.matchedRegions.size }
        val avgMatches = if (edges.isNotEmpty()) totalMatches / edges.size else 0
        return "Linked by shared visual features (~$avgMatches matching points per pair)."
    }
}
