package com.example.sih

import org.junit.Assert.*
import org.junit.Test
import org.opencv.core.Mat
import org.opencv.core.MatOfKeyPoint
import org.opencv.core.Point
import org.opencv.core.KeyPoint

class ClustererTest {

    @Test
    fun testConnectedComponentsClustering() {
        val clusterer = Clusterer()
        
        // Mock 3 documents that should form a cluster
        val edges = listOf(
            PairwiseComparisonResult("docA", "docB", 0.8f, SimilarityBand.HIGH, emptyList(), ""),
            PairwiseComparisonResult("docB", "docC", 0.7f, SimilarityBand.MEDIUM, emptyList(), "")
        )
        
        val clusters = clusterer.clusterDocuments(edges)
        
        assertEquals(1, clusters.size)
        
        val cluster = clusters.first()
        assertTrue(cluster.memberIds.containsAll(listOf("docA", "docB", "docC")))
        assertEquals(SimilarityBand.HIGH, cluster.overallBand)
    }

    @Test
    fun testDisjointClusters() {
        val clusterer = Clusterer()
        
        // Two separate clusters
        val edges = listOf(
            PairwiseComparisonResult("docA", "docB", 0.8f, SimilarityBand.HIGH, emptyList(), ""),
            PairwiseComparisonResult("docX", "docY", 0.6f, SimilarityBand.LOW, emptyList(), "")
        )
        
        val clusters = clusterer.clusterDocuments(edges)
        
        assertEquals(2, clusters.size)
    }
}
