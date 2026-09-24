package com.example.sih

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class SimilarityPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private val scope = CoroutineScope(Dispatchers.Default)
    
    private val config = SimilarityConfig()
    private val extractor = FeatureExtractor()
    private val engine = SimilarityEngine(config)
    private val clusterer = Clusterer()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.example.sih/similarity")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "runClustering" -> {
                // Expects a list of map containing id and imagePath
                val documentsData = call.arguments as? List<Map<String, String>>
                if (documentsData == null) {
                    result.error("INVALID_ARGS", "Expected list of document maps", null)
                    return
                }
                
                val records = documentsData.map { 
                    DocumentRecord(it["id"] ?: "", it["imagePath"] ?: "") 
                }

                // Run heavy processing in background coroutine
                scope.launch {
                    try {
                        val clusters = processDocuments(records)
                        withContext(Dispatchers.Main) {
                            result.success(serializeClusters(clusters))
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("PROCESSING_ERROR", e.message, null)
                        }
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun processDocuments(records: List<DocumentRecord>): List<ClusterExplanation> {
        // 1. Extract features
        val features = records.map { extractor.extractFeatures(it) }
        
        // 2. Pairwise comparison
        val comparisons = mutableListOf<PairwiseComparisonResult>()
        for (i in features.indices) {
            for (j in i + 1 until features.size) {
                comparisons.add(engine.compare(features[i], features[j]))
            }
        }
        
        // 3. Cluster
        return clusterer.clusterDocuments(comparisons)
    }

    private fun serializeClusters(clusters: List<ClusterExplanation>): List<Map<String, Any>> {
        return clusters.map { cluster ->
            mapOf(
                "clusterId" to cluster.clusterId,
                "memberIds" to cluster.memberIds,
                "overallBand" to cluster.overallBand.name,
                "summary" to cluster.summary,
                "edges" to cluster.edges.map { edge ->
                    mapOf(
                        "docId1" to edge.docId1,
                        "docId2" to edge.docId2,
                        "similarityScore" to edge.similarityScore,
                        "band" to edge.band.name,
                        "matchedRegions" to edge.matchedRegions.map { region ->
                            mapOf(
                                "qX" to region.queryPointX,
                                "qY" to region.queryPointY,
                                "tX" to region.trainPointX,
                                "tY" to region.trainPointY
                            )
                        }
                    )
                }
            )
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
