package com.example.sih

import org.opencv.core.MatOfDMatch
import org.opencv.features2d.BFMatcher
import org.opencv.core.Core

enum class SimilarityBand {
    LOW, MEDIUM, HIGH, NONE
}

data class MatchedRegion(
    val queryPointX: Double,
    val queryPointY: Double,
    val trainPointX: Double,
    val trainPointY: Double
)

data class PairwiseComparisonResult(
    val docId1: String,
    val docId2: String,
    val similarityScore: Float, // 0.0 to 1.0
    val band: SimilarityBand,
    val matchedRegions: List<MatchedRegion>,
    val explanation: String
)

class SimilarityEngine(private val config: SimilarityConfig = SimilarityConfig()) {

    // Brute-force matcher with Hamming distance for ORB
    private val matcher = BFMatcher.create(Core.NORM_HAMMING, true)

    fun compare(features1: DocumentFeatures, features2: DocumentFeatures): PairwiseComparisonResult {
        if (features1.descriptors.empty() || features2.descriptors.empty()) {
             return PairwiseComparisonResult(features1.recordId, features2.recordId, 0f, SimilarityBand.NONE, emptyList(), "No features to match.")
        }

        val matches = MatOfDMatch()
        matcher.match(features1.descriptors, features2.descriptors, matches)

        val matchArray = matches.toArray()
        
        // Filter good matches based on distance
        val goodMatches = matchArray.filter { it.distance <= config.orbHammingDistanceThreshold }

        val numMatches = goodMatches.size
        
        val band = when {
            numMatches >= config.matchThresholdHigh -> SimilarityBand.HIGH
            numMatches >= config.matchThresholdMedium -> SimilarityBand.MEDIUM
            numMatches >= config.matchThresholdLow -> SimilarityBand.LOW
            else -> SimilarityBand.NONE
        }

        // Calculate a score bounded between 0 and 1. 
        // We cap the score to avoid displaying raw percentages, but keep it internally for graph weights.
        val maxMatchesExpected = 100f
        val visualScore = (numMatches.toFloat() / maxMatchesExpected).coerceIn(0f, 1f)
        
        val structuralScore = if (features1.structuralHash == features2.structuralHash) 1.0f else 0.0f
        
        val finalScore = (visualScore * config.visualWeight) + (structuralScore * config.structuralWeight)

        // Extract matched regions for explainability
        val kps1 = features1.keypoints.toArray()
        val kps2 = features2.keypoints.toArray()
        
        val matchedRegions = goodMatches.map { match ->
            val pt1 = kps1[match.queryIdx].pt
            val pt2 = kps2[match.trainIdx].pt
            MatchedRegion(pt1.x, pt1.y, pt2.x, pt2.y)
        }

        val explanation = buildExplanation(band, numMatches, structuralScore > 0)

        return PairwiseComparisonResult(
            docId1 = features1.recordId,
            docId2 = features2.recordId,
            similarityScore = finalScore,
            band = band,
            matchedRegions = matchedRegions,
            explanation = explanation
        )
    }

    private fun buildExplanation(band: SimilarityBand, numMatches: Int, structuralMatch: Boolean): String {
        if (band == SimilarityBand.NONE) return "No significant similarity found."
        
        val parts = mutableListOf<String>()
        parts.add("Found $numMatches visual matching points.")
        if (structuralMatch) {
            parts.add("Structural layout also matches.")
        }
        return parts.joinToString(" ")
    }
}
