import 'package:flutter/material.dart';
import '../models.dart';
import '../services/document_loader.dart';
import '../services/corridor_engine.dart';
import '../services/tamper_analyzer.dart';
import '../services/syndicate_clusterer.dart';
import '../services/audit_trail_service.dart';
import '../widgets/corridor_card.dart';
import '../widgets/document_inspector_modal.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<DocumentRecord> _documents = [];
  List<CorridorRiskProfile> _corridors = [];
  List<SyndicateCluster> _clusters = [];
  List<AuditTrailEntry> _auditTrail = [];
  bool _chainIntegrityValid = true;

  // Filter states
  String _docFilter = 'ALL'; // ALL, TAMPERED, CLEAN
  String _searchQuery = '';
  String _selectedCorridorFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final docs = await DocumentLoader.loadDocuments();
    final corridors = CorridorEngine.computeCorridorProfiles(docs);
    final clusters = SyndicateClusterer.clusterDocuments(docs);
    final audit = AuditTrailService.generateAuditTrail(docs);
    final valid = AuditTrailService.verifyChainIntegrity();

    setState(() {
      _documents = docs;
      _corridors = corridors;
      _clusters = clusters;
      _auditTrail = audit;
      _chainIntegrityValid = valid;
      _isLoading = false;
    });
  }

  int get _tamperedTotal =>
      _documents.where((d) => TamperAnalyzer.analyzeDocument(d).isTampered).length;

  int get _criticalCorridorsCount =>
      _corridors.where((c) => c.dangerRating == DangerRating.critical).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
              ),
              child: const Icon(Icons.shield_rounded, color: Color(0xFF38BDF8), size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "VIGIL-BORDER // THREAT INTEL",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.8,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "OFFLINE SECURE MODE  •  ICAO 9303 OCR PIPELINE",
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Rescan & Reload Documents from Disk",
            icon: const Icon(Icons.sync_rounded, color: Color(0xFF38BDF8)),
            onPressed: () async {
              await _loadData();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF1E293B),
                  content: Text(
                    "Corpus reloaded: ${_documents.length} docs screened ($_tamperedTotal tampered detected)",
                    style: const TextStyle(color: Colors.white),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            tooltip: "Verify Cryptographic Audit Trail",
            icon: Icon(
              _chainIntegrityValid ? Icons.verified_user_rounded : Icons.gpp_bad_rounded,
              color: _chainIntegrityValid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
            onPressed: _showIntegrityDialog,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF38BDF8),
          indicatorWeight: 3,
          labelColor: const Color(0xFF38BDF8),
          unselectedLabelColor: const Color(0xFF94A3B8),
          tabs: const [
            Tab(icon: Icon(Icons.alt_route_rounded), text: "Corridors"),
            Tab(icon: Icon(Icons.document_scanner_rounded), text: "Inspector"),
            Tab(icon: Icon(Icons.history_edu_rounded), text: "Audit Trail"),
            Tab(icon: Icon(Icons.hub_rounded), text: "Syndicates"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCorridorsTab(),
                _buildInspectorTab(),
                _buildAuditTrailTab(),
                _buildSyndicatesTab(),
              ],
            ),
    );
  }

  // --- TAB 1: CORRIDOR THREAT INTELLIGENCE ---
  Widget _buildCorridorsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF38BDF8),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildMetricsOverview(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "TRANSIT CORRIDOR WATCHLIST (SOURCE → DESTINATION)",
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          if (_corridors.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text("No corridors recorded.", style: TextStyle(color: Color(0xFF64748B))),
              ),
            )
          else
            ..._corridors.map((c) => CorridorCard(
                  profile: c,
                  onTap: () {
                    // Filter inspector by this corridor and switch tab
                    setState(() {
                      _selectedCorridorFilter = c.corridor;
                      _tabController.animateTo(1);
                    });
                  },
                )),
        ],
      ),
    );
  }

  Widget _buildMetricsOverview() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "BORDER SURVEILLANCE & THREAT OVERVIEW",
            style: TextStyle(
              color: Color(0xFF38BDF8),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetricTile(
                "Documents Screened",
                "${_documents.length}",
                Icons.description_outlined,
                const Color(0xFF38BDF8),
              ),
              const SizedBox(width: 10),
              _buildMetricTile(
                "Tampered Flagged",
                "$_tamperedTotal",
                Icons.warning_amber_rounded,
                const Color(0xFFEF4444),
              ),
              const SizedBox(width: 10),
              _buildMetricTile(
                "Critical Corridors",
                "$_criticalCorridorsCount",
                Icons.alt_route_rounded,
                const Color(0xFFF97316),
              ),
              const SizedBox(width: 10),
              _buildMetricTile(
                "Active Rings",
                "${_clusters.length}",
                Icons.hub_outlined,
                const Color(0xFFA855F7),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF162032),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: DOCUMENT TAMPER INSPECTOR ---
  Widget _buildInspectorTab() {
    var filtered = _documents.where((doc) {
      if (_selectedCorridorFilter != 'ALL' && doc.corridor != _selectedCorridorFilter) {
        return false;
      }
      final analysis = TamperAnalyzer.analyzeDocument(doc);
      if (_docFilter == 'TAMPERED' && !analysis.isTampered) return false;
      if (_docFilter == 'CLEAN' && analysis.isTampered) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = doc.name.toLowerCase().contains(q) ||
            doc.docId.toLowerCase().contains(q) ||
            doc.docNum.toLowerCase().contains(q) ||
            doc.corridor.toLowerCase().contains(q);
        if (!matches) return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF0F172A),
          child: Column(
            children: [
              TextField(
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Search by Name, Doc ID, Passport No, or Corridor...",
                  hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF38BDF8), size: 18),
                  filled: true,
                  fillColor: const Color(0xFF162032),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF1E293B)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF1E293B)),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildFilterChip('ALL', 'All (${_documents.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('TAMPERED', 'Tampered Only ($_tamperedTotal)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('CLEAN', 'Clean / Verified'),
                  const Spacer(),
                  if (_selectedCorridorFilter != 'ALL')
                    GestureDetector(
                      onTap: () => setState(() => _selectedCorridorFilter = 'ALL'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Text("Clear Route Filter", style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11)),
                            SizedBox(width: 4),
                            Icon(Icons.close, size: 12, color: Color(0xFF38BDF8)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Document List
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text("No documents match current filters.", style: TextStyle(color: Color(0xFF64748B))),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final analysis = TamperAnalyzer.analyzeDocument(doc);
                    final danger = analysis.dangerRating;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      color: const Color(0xFF162032),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: analysis.isTampered ? danger.color.withOpacity(0.4) : const Color(0xFF1E293B),
                        ),
                      ),
                      child: ListTile(
                        onTap: () => _openInspector(doc),
                        leading: CircleAvatar(
                          backgroundColor: danger.bgColor,
                          child: Icon(
                            analysis.isTampered ? Icons.warning_rounded : Icons.check_circle_outline_rounded,
                            color: danger.color,
                            size: 20,
                          ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${doc.docId} • ${doc.name}",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: danger.bgColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                danger.label,
                                style: TextStyle(color: danger.color, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 3),
                            Text(
                              "Route: ${doc.corridor}",
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            ),
                            if (analysis.isTampered)
                              Text(
                                "Findings: ${analysis.findings.map((f) => f.category).join(', ')}",
                                style: const TextStyle(color: Color(0xFFF87171), fontSize: 11),
                              ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF64748B)),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _docFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _docFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF162032),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  // --- TAB 3: AUDIT TRAIL & LOGS ---
  Widget _buildAuditTrailTab() {
    return Column(
      children: [
        // Audit Chain Integrity Banner
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _chainIntegrityValid ? const Color(0x1A10B981) : const Color(0x1AEF4444),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _chainIntegrityValid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _chainIntegrityValid ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                color: _chainIntegrityValid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _chainIntegrityValid
                          ? "CRYPTOGRAPHIC AUDIT CHAIN VERIFIED (SHA-256)"
                          : "AUDIT CHAIN INTEGRITY BREACH DETECTED",
                      style: TextStyle(
                        color: _chainIntegrityValid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _chainIntegrityValid
                          ? "All ${_auditTrail.length} recorded events are immutably anchored. Post-hoc manipulation is mathematically impossible."
                          : "Warning: Stored cryptographic hashes do not match chain block sequence.",
                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Log Entries List
        Expanded(
          child: ListView.builder(
            itemCount: _auditTrail.length,
            itemBuilder: (context, index) {
              final entry = _auditTrail[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: const Color(0xFF162032),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFF1E293B)),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: entry.dangerRating.bgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "#${entry.blockIndex}",
                      style: TextStyle(
                        color: entry.dangerRating.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${entry.docId} • ${entry.passengerName}",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: entry.dangerRating.bgColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entry.dangerRating.label,
                          style: TextStyle(
                            color: entry.dangerRating.color,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    "Corridor: ${entry.corridor}",
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Tampering Diagnosis: ${entry.tamperSummary}",
                            style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          ...entry.detectedAnomalies.map((a) => Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text("• $a", style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                              )),
                          const Divider(color: Color(0xFF334155), height: 16),
                          Row(
                            children: [
                              const Text("Block Hash (SHA-256): ", style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                              Expanded(
                                child: Text(
                                  entry.hash,
                                  style: const TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Text("Previous Hash: ", style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                              Expanded(
                                child: Text(
                                  entry.previousHash,
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Timestamp: ${entry.timestamp.toIso8601String()}",
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- TAB 4: SYNDICATES & CLUSTERING ---
  Widget _buildSyndicatesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Explanatory Banner: HOW CLUSTERING WORKS
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131C2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology_alt_rounded, color: Color(0xFF38BDF8), size: 20),
                  SizedBox(width: 8),
                  Text(
                    "HOW SYNDICATE CLUSTERING OPERATES (NOT SIMPLE SIMILARITY)",
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                "Traditional similarity checkers only measure pixel overlap, generating high false positives on shared passport templates. Our engine clusters across 3 correlated forensic vectors:\n"
                "1. Toolmark & Stamp Fingerprinting: Cloned digital seals (Kit-A, Kit-B, Kit-C) with fixed rotational angles.\n"
                "2. Transit Route Convergence: Identifies clusters sharing Source departure points and destination bottlenecks.\n"
                "3. Invariant Modus Operandi: Correlates identical DOB spoofing templates and invalid MRZ polynomial checksums.",
                style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          "DETECTED FRAUD RINGS & TOOLMARK CELLS",
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),

        ..._clusters.map((cluster) {
          final danger = cluster.threatLevel;
          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            color: const Color(0xFF162032),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: danger.color.withOpacity(0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          cluster.syndicateName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: danger.bgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          danger.label,
                          style: TextStyle(color: danger.color, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cluster.technicalSummary,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.3),
                  ),
                  const SizedBox(height: 10),

                  // Common Modus
                  const Text(
                    "Correlated Modus Operandi:",
                    style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...cluster.commonModusOperandi.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 2.0),
                        child: Text("• $m", style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 11)),
                      )),

                  const Divider(color: Color(0xFF1E293B), height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Member Credentials: ${cluster.memberDocuments.length} docs intercepted",
                        style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      TextButton(
                        onPressed: () {
                          // Filter inspector by this syndicate group
                          setState(() {
                            _searchQuery = cluster.clusterId.replaceAll("RING-", "");
                            _tabController.animateTo(1);
                          });
                        },
                        child: const Text("Inspect Member Docs →", style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _openInspector(DocumentRecord doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DocumentInspectorModal(document: doc),
    );
  }

  void _showIntegrityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              _chainIntegrityValid ? Icons.verified_user_rounded : Icons.warning_amber_rounded,
              color: _chainIntegrityValid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
            const SizedBox(width: 10),
            const Text(
              "Audit Trail Integrity",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          _chainIntegrityValid
              ? "All ${_auditTrail.length} tamper audit blocks have been mathematically validated using SHA-256 forward-chaining. Zero alterations or record deletions detected."
              : "Chain validation failed. One or more records have been tampered with or corrupted.",
          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
