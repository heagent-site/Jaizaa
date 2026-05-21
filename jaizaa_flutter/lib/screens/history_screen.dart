import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/patient_provider.dart';
import '../providers/analysis_provider.dart';
import '../config/theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientProvider>();

    return Scaffold(
      backgroundColor: JaizaaTheme.background,
      appBar: AppBar(
        backgroundColor: JaizaaTheme.surface,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.description, color: JaizaaTheme.primary),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false),
        ),
        title: GestureDetector(
          onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false),
          child: const Text(
            'Jaizaa',
            style: TextStyle(
              color: JaizaaTheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: JaizaaTheme.primary),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      body: provider.isLoadingHistory
          ? const Center(child: CircularProgressIndicator(color: JaizaaTheme.primary))
          : provider.history.isEmpty
              ? _buildEmptyState()
              : _buildHistoryList(provider),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/upload'),
        backgroundColor: JaizaaTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: JaizaaTheme.surface,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          currentIndex: 2,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: JaizaaTheme.primary,
          unselectedItemColor: JaizaaTheme.textSecondary,
          selectedLabelStyle: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.w500, fontSize: 12),
          onTap: (index) {
            if (index == 0) Navigator.pushReplacementNamed(context, '/');
            if (index == 1) Navigator.pushReplacementNamed(context, '/patients');
            // index == 2 is current screen
          },
          items: const [
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_outlined)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home)),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.people_outline)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.people)),
              label: 'Patients',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.history)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.history)),
              label: 'History',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No analyses yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap '+' to analyze a report.",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(PatientProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: JaizaaTheme.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: JaizaaTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${provider.history.length} TOTAL',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: JaizaaTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: provider.history.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = provider.history[index];
              return _buildHistoryCard(entry);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> entry) {
    final name = entry['name']?.toString() ?? 'Unknown';
    final riskLevel = (entry['risk_level'] ?? 'UNKNOWN').toString().toUpperCase();
    final analyzedAt = entry['last_analyzed_at']?.toString() ?? '';
    final patientId = entry['patient_id']?.toString() ?? '';

    // Parse analysis result for summary
    final rawResult = entry['last_analysis_result'];
    Map<String, dynamic>? analysisResult;
    if (rawResult is Map) {
      analysisResult = Map<String, dynamic>.from(rawResult);
    } else if (rawResult is String) {
      try {
        analysisResult = Map<String, dynamic>.from(jsonDecode(rawResult));
      } catch (_) {}
    }

    // Build summary line
    int patternsCount = 0;
    int actionsCount = 0;
    if (analysisResult != null) {
      final rawFindings = analysisResult['findings'];
      if (rawFindings is List) {
        patternsCount = rawFindings.length;
      } else if (rawFindings is Map) {
        final findings = rawFindings['findings'] ?? rawFindings['data'];
        if (findings is List) patternsCount = findings.length;
      }

      final rawActions = analysisResult['action_plan'];
      if (rawActions is List) {
        actionsCount = rawActions.length;
      } else if (rawActions is Map) {
        final actions = rawActions['action_plan'] ?? rawActions['data'];
        if (actions is List) actionsCount = actions.length;
      }
    }

    final summaryLine = '$patternsCount pattern${patternsCount != 1 ? 's' : ''} detected · $actionsCount action${actionsCount != 1 ? 's' : ''} executed';

    // Format date
    String displayDate = '';
    if (analyzedAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(analyzedAt);
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        displayDate = '${months[dt.month - 1]} ${dt.day}, ${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        displayDate = analyzedAt.length >= 10 ? analyzedAt.substring(0, 10) : analyzedAt;
      }
    }

    // Risk colors
    Color riskColor = JaizaaTheme.lowSafe;
    Color badgeBg = Colors.grey.shade200;
    Color badgeText = Colors.grey.shade800;
    if (riskLevel == 'CRITICAL') {
      riskColor = JaizaaTheme.criticalRed;
      badgeBg = const Color(0xFFFFDAD6);
      badgeText = const Color(0xFF93000A);
    } else if (riskLevel == 'HIGH') {
      riskColor = JaizaaTheme.highWarning;
      badgeBg = const Color(0xFFFFF3E0);
      badgeText = JaizaaTheme.highWarning;
    } else if (riskLevel == 'MEDIUM') {
      riskColor = JaizaaTheme.mediumCaution;
      badgeBg = const Color(0xFFFFF9C4);
      badgeText = const Color(0xFFF57F17);
    } else if (riskLevel == 'LOW') {
      riskColor = JaizaaTheme.lowSafe;
      badgeBg = const Color(0xFFE8F5E9);
      badgeText = const Color(0xFF2E7D32);
    }

    // Initials
    String initials = '??';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      initials = name.substring(0, name.length > 1 ? 2 : 1).toUpperCase();
    }

    return GestureDetector(
      onTap: () async {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        final success = await context
            .read<AnalysisProvider>()
            .loadPatientAnalysis(patientId);

        if (context.mounted) {
          Navigator.pop(context); // dismiss loading
          if (success) {
            Navigator.pushNamed(context, '/results');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No analysis details found for $name.')),
            );
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: JaizaaTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left color stripe
              Container(width: 4, color: riskColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: avatar + name + risk badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.grey.shade200,
                            child: Text(
                              initials,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: JaizaaTheme.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: JaizaaTheme.textPrimary)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.schedule, size: 13, color: JaizaaTheme.textSecondary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        displayDate,
                                        style: const TextStyle(fontSize: 12, color: JaizaaTheme.textSecondary, fontFamily: 'JetBrains Mono'),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: badgeText.withOpacity(0.2)),
                            ),
                            child: Text(
                              riskLevel,
                              style: TextStyle(color: badgeText, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Summary line
                      Row(
                        children: [
                          const Icon(Icons.analytics_outlined, size: 14, color: JaizaaTheme.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              summaryLine,
                              style: const TextStyle(fontSize: 13, color: JaizaaTheme.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: JaizaaTheme.primary, size: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
