package com.example.sih

/**
 * Configuration for the document similarity clustering module.
 * Values can be tuned based on real-world testing.
 */
data class SimilarityConfig(
    // The minimum number of matched ORB keypoints to consider two documents "similar"
    val matchThresholdLow: Int = 15,
    val matchThresholdMedium: Int = 30,
    val matchThresholdHigh: Int = 50,
    
    // Weight given to visual features (ORB) vs structural features
    val visualWeight: Float = 0.8f,
    val structuralWeight: Float = 0.2f,

    // Distance threshold for ORB Hamming distance
    val orbHammingDistanceThreshold: Float = 50.0f
)
