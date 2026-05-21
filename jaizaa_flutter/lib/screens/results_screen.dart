import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analysis_provider.dart';
import '../providers/patient_provider.dart';
import '../config/theme.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingInsights = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Simulate staggered loading for insights
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoadingInsights = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = context.watch<AnalysisProvider>().fullResult;
    
    if (result == null) {
      return const Scaffold(body: Center(child: Text("No result data")));
    }

    final riskLevel = result['risk']['overall_risk'] as String;
    final Color riskColor = _riskColor(riskLevel);

    return Scaffold(
      backgroundColor: JaizaaTheme.background,
      appBar: AppBar(
        backgroundColor: JaizaaTheme.surface,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: JaizaaTheme.primary),
          onPressed: () => Navigator.pop(context),
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
      body: Column(
        children: [
          // Risk Indicator Bar
          Container(
            width: double.infinity,
            height: 8,
            color: riskColor,
          ),
          
          // Patient Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result['report']?['before']?['name'] ?? 'Unknown Patient', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: JaizaaTheme.textPrimary)),
                      const SizedBox(height: 4),
                      Text('ID: PT-${result['report']?['before']?['patient_id'] ?? ''} • Phone: ${result['report']?['before']?['phone'] ?? 'N/A'}', style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: JaizaaTheme.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: riskColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: riskColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Icon(_riskIcon(riskLevel), color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$riskLevel RISK',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Custom TabBar
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: JaizaaTheme.primary,
              unselectedLabelColor: JaizaaTheme.textSecondary,
              labelStyle: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.normal),
              indicatorColor: JaizaaTheme.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Insights'),
                Tab(text: 'Actions'),
                Tab(text: 'Logs'),
              ],
            ),
          ),

          // Tab Contents
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInsightsTab(result),
                _buildActionsTab(context, result),
                _buildLogsTab(result),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(Map<String, dynamic> result) {
    if (_isLoadingInsights) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: JaizaaTheme.primary),
            const SizedBox(height: 16),
            Text('Analyzing clinical data...', style: TextStyle(fontFamily: 'JetBrains Mono', color: JaizaaTheme.primary.withOpacity(0.8))),
          ],
        ),
      );
    }

    final rawFindings = result['findings'];
    final List<dynamic> findings = rawFindings is List ? rawFindings : (rawFindings['findings'] ?? rawFindings['data'] ?? []);

    if (findings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green.shade200, width: 2),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: Colors.green.shade700,
                  size: 80,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "All values within normal range",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: JaizaaTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "No clinical patterns detected. Patient appears healthy based on this report.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: findings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final f = findings[index];
        final confidence = (f['confidence'] * 100).toInt();
        
        return Container(
          decoration: BoxDecoration(
            color: JaizaaTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.medical_services, color: JaizaaTheme.highWarning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f['pattern'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: JaizaaTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified, color: JaizaaTheme.primary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '$confidence%',
                            style: const TextStyle(fontFamily: 'JetBrains Mono', color: JaizaaTheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Critical Values
              if (f['values_involved'] != null && (f['values_involved'] as List).isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CRITICAL VALUES DETECTED', style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: JaizaaTheme.textSecondary, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      ...((f['values_involved'] as List).map((val) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(val.toString().split(' ').first, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: JaizaaTheme.highWarning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                val.toString(),
                                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: JaizaaTheme.highWarning, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ))),
                    ],
                  ),
                ),
              
              // Explanation
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  f['explanation'],
                  style: const TextStyle(fontSize: 14, color: JaizaaTheme.textSecondary, height: 1.5),
                ),
              ),

              // Action Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _tabController.animateTo(2),
                      icon: const Text('View Full Context', style: TextStyle(fontFamily: 'JetBrains Mono', color: JaizaaTheme.primary)),
                      label: const Icon(Icons.arrow_forward, color: JaizaaTheme.primary, size: 16),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        backgroundColor: JaizaaTheme.primary.withOpacity(0.05),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionsTab(BuildContext context, Map<String, dynamic> result) {
    final provider = context.watch<AnalysisProvider>();
    final rawActions = result['action_plan'];
    final List<dynamic> rawList = rawActions is List ? rawActions : (rawActions['action_plan'] ?? rawActions['data'] ?? []);
    final riskLevel = result['risk']?['overall_risk']?.toString().toUpperCase() ?? 'LOW';

    final List<MapEntry<int, dynamic>> actionsWithIndex = [];
    for (int i = 0; i < rawList.length; i++) {
      final action = rawList[i];
      final type = action['action_type']?.toString().toLowerCase();
      if (riskLevel != 'LOW' || type == 'app_record_update') {
        actionsWithIndex.add(MapEntry(i, action));
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: actionsWithIndex.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = actionsWithIndex[index];
                final originalIndex = entry.key;
                final action = entry.value;
                final type = action['action_type'].toString();
                final priority = action['priority'].toString().toUpperCase();
                final isApproved = provider.isActionApproved(originalIndex);
                
                // Display name mapping
                String displayType = type.replaceAll('_', ' ').toUpperCase();
                if (type == 'app_record_update') {
                  displayType = 'PATIENT RECORD UPDATE';
                }
                
                // Color based on priority
                Color priorityColor = JaizaaTheme.lowSafe;
                if (priority == 'URGENT' || priority == 'CRITICAL') {
                  priorityColor = JaizaaTheme.criticalRed;
                } else if (priority == 'HIGH') {
                  priorityColor = JaizaaTheme.highWarning;
                } else if (priority == 'MEDIUM') {
                  priorityColor = JaizaaTheme.mediumCaution;
                }

                Widget actionDetails = const SizedBox.shrink();
                Widget? integrationNote;
                
                switch (type) {
                  case 'appointment':
                    actionDetails = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Specialist', action['specialty'] ?? 'N/A', Icons.person_search),
                        _buildDetailRow('Reason', action['reason'] ?? 'N/A', Icons.healing),
                        _buildDetailRow('Scheduled Slot', action['scheduled_slot'] ?? 'N/A', Icons.calendar_month),
                      ],
                    );
                    integrationNote = _buildIntegrationNote(
                      Icons.calendar_today,
                      'Connect your Calendar app to enable auto-booking',
                      const Color(0xFF1565C0),
                    );
                    break;
                  case 'alert':
                    final flagged = action['flagged_values'] ?? {};
                    final flaggedStr = flagged is Map 
                        ? flagged.entries.map((e) => "${e.key}: ${e.value}").join(", ")
                        : flagged.toString();
                    actionDetails = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Urgency', action['urgency_level'] ?? 'N/A', Icons.speed),
                        _buildDetailRow('Clinical Pattern', action['clinical_pattern'] ?? 'N/A', Icons.analytics),
                        _buildDetailRow('Flagged Values', flaggedStr, Icons.rule),
                        _buildDetailRow('Alert Message', action['message'] ?? 'N/A', Icons.chat_bubble_outline),
                      ],
                    );
                    break;
                  case 'notification':
                    actionDetails = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Channel', action['channel'] ?? 'WhatsApp', Icons.phone_android),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.chat_bubble, color: Color(0xFF25D366), size: 20),
                                  SizedBox(width: 6),
                                  Text('WHATSAPP DRAFT', style: TextStyle(fontFamily: 'JetBrains Mono', color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                action['message_text'] ?? 'N/A',
                                style: const TextStyle(fontSize: 14, color: Color(0xFF1B1C1C), height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                    integrationNote = _buildIntegrationNote(
                      Icons.chat,
                      'Connect WhatsApp to send this message automatically',
                      const Color(0xFF25D366),
                    );
                    break;
                  case 'app_record_update':
                    final updates = action['updates'] ?? {};
                    actionDetails = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Risk Level Update', updates['risk_level'] ?? 'N/A', Icons.trending_up),
                        _buildDetailRow('Follow-up Status', updates['follow_up_status'] ?? 'N/A', Icons.rotate_right),
                        _buildDetailRow('Care Gap', updates['care_gap'] ?? 'N/A', Icons.health_and_safety),
                      ],
                    );
                    break;
                  default:
                    actionDetails = Text(action.toString(), style: const TextStyle(fontSize: 14, color: JaizaaTheme.textSecondary));
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isApproved ? JaizaaTheme.primary.withOpacity(0.03) : JaizaaTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isApproved ? JaizaaTheme.primary.withOpacity(0.3) : Colors.grey.shade200),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(_actionIcon(type), color: JaizaaTheme.primary, size: 22),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    displayType,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: priorityColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  priority,
                                  style: TextStyle(color: priorityColor, fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (isApproved) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: JaizaaTheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, color: JaizaaTheme.primary, size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        'APPROVED',
                                        style: TextStyle(color: JaizaaTheme.primary, fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 1),
                      actionDetails,
                      if (integrationNote != null) ...[
                        const SizedBox(height: 12),
                        integrationNote,
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isApproved)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check, size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 6),
                                  Text('Approved', style: TextStyle(fontFamily: 'JetBrains Mono', color: Colors.grey.shade600)),
                                ],
                              ),
                            )
                          else
                            OutlinedButton.icon(
                              onPressed: () {
                                context.read<AnalysisProvider>().toggleActionApproval(originalIndex);
                              },
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Approve', style: TextStyle(fontFamily: 'JetBrains Mono')),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: JaizaaTheme.primary,
                                side: const BorderSide(color: JaizaaTheme.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _executeAllApproved(context, result),
              style: ElevatedButton.styleFrom(
                backgroundColor: JaizaaTheme.criticalRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'EXECUTE ALL (${context.watch<AnalysisProvider>().approvedCount} approved)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _executeAllApproved(BuildContext context, Map<String, dynamic> result) async {
    final provider = context.read<AnalysisProvider>();
    final patientProvider = context.read<PatientProvider>();
    final rawActions = result['action_plan'];
    final List<dynamic> actions = rawActions is List ? rawActions : (rawActions['action_plan'] ?? rawActions['data'] ?? []);

    if (provider.approvedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please approve at least one action before executing.'),
          backgroundColor: JaizaaTheme.highWarning,
        ),
      );
      return;
    }

    // Show execution dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.sync, color: JaizaaTheme.primary),
            SizedBox(width: 8),
            Text('Executing Actions...'),
          ],
        ),
        content: const LinearProgressIndicator(color: JaizaaTheme.primary),
      ),
    );

    // Process each approved action
    final List<String> executionResults = [];
    
    for (int i = 0; i < actions.length; i++) {
      if (!provider.isActionApproved(i)) continue;
      
      final action = actions[i];
      final type = action['action_type'].toString();
      
      await Future.delayed(const Duration(milliseconds: 500)); // simulate processing
      
      switch (type) {
        case 'alert':
          // Trigger in-app notification by refreshing alerts
          patientProvider.loadAlerts();
          executionResults.add('ALERT: In-app notification triggered');
          break;
        case 'app_record_update':
          // Database write happens on the backend during analysis — already persisted
          executionResults.add('PATIENT RECORD UPDATE: Database updated');
          break;
        case 'appointment':
          executionResults.add('APPOINTMENT: Saved locally — Pending Integration');
          break;
        case 'notification':
          executionResults.add('NOTIFICATION: Draft saved — Pending Integration');
          break;
      }
    }

    if (context.mounted) {
      Navigator.pop(context); // dismiss loading dialog
      
      // Show results summary
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${executionResults.length} action(s) executed successfully'),
          backgroundColor: JaizaaTheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate to before/after comparison
      await Future.delayed(const Duration(milliseconds: 500));
      if (context.mounted) {
        Navigator.pushNamed(context, '/before_after');
      }
    }
  }

  Widget _buildIntegrationNote(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: color.withOpacity(0.8), fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: JaizaaTheme.textSecondary),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, fontWeight: FontWeight.bold, color: JaizaaTheme.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: JaizaaTheme.textPrimary, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsTab(Map<String, dynamic> result) {
    final trace = (result['report']?['agent_trace'] as List?) ?? [];
    final patientName = result['report']?['before']?['name'] ?? 'Patient';
    final rawDate = result['values']?['report_date'] ?? '';
    
    String getFormattedDate(String dateStr) {
      if (dateStr == 'N/A' || dateStr.isEmpty) return 'recently';
      try {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          final year = parts[0];
          final monthInt = int.tryParse(parts[1]) ?? 1;
          final day = int.tryParse(parts[2]) ?? 1;
          final months = [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
          ];
          if (monthInt >= 1 && monthInt <= 12) {
            final monthName = months[monthInt - 1];
            return "$monthName $day, $year";
          }
        }
      } catch (_) {}
      return dateStr;
    }

    final displayDate = getFormattedDate(rawDate.toString());

    String getReadableTitle(String agent) {
      switch (agent.toLowerCase().replaceAll(' ', '_').replaceAll('_', '')) {
        case 'documentreader':
          return 'Lab Report Scanned';
        case 'clinicalanalyzer':
          return 'Clinical Patterns Checked';
        case 'riskassessor':
          return 'Health Risk Evaluated';
        case 'actionplanner':
          return 'Follow-up Recommendations Generated';
        case 'executionagent':
          return 'Actions Registered & Synced';
        case 'outcomereporter':
          return 'Patient Record Updated';
        default:
          return agent;
      }
    }

    IconData getReadableIcon(String agent) {
      switch (agent.toLowerCase().replaceAll(' ', '_').replaceAll('_', '')) {
        case 'documentreader':
          return Icons.document_scanner_outlined;
        case 'clinicalanalyzer':
          return Icons.healing_outlined;
        case 'riskassessor':
          return Icons.analytics_outlined;
        case 'actionplanner':
          return Icons.playlist_add_check_outlined;
        case 'executionagent':
          return Icons.sync_outlined;
        case 'outcomereporter':
          return Icons.assignment_turned_in_outlined;
        default:
          return Icons.info_outline;
      }
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: trace.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final t = trace[index];
        final agent = t['agent']?.toString() ?? 'System';
        final status = t['status']?.toString().toUpperCase() ?? 'IN_PROGRESS';
        final output = t['key_output']?.toString() ?? '';

        final title = getReadableTitle(agent);
        final icon = getReadableIcon(agent);

        Color statusBgColor = const Color(0xFFFFF9C4);
        Color statusTextColor = const Color(0xFFF57F17);
        String statusText = 'In Progress';

        if (status == 'DONE' || status == 'SUCCESS') {
          statusBgColor = const Color(0xFFE8F5E9);
          statusTextColor = const Color(0xFF2E7D32);
          statusText = 'Done';
        } else if (status == 'ERROR' || status == 'FAILED') {
          statusBgColor = const Color(0xFFFFDAD6);
          statusTextColor = const Color(0xFF93000A);
          statusText = 'Failed';
        }

        return Container(
          decoration: BoxDecoration(
            color: JaizaaTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon column
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: JaizaaTheme.primary.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: JaizaaTheme.primary, size: 24),
                ),
                const SizedBox(width: 16),
                // Text details column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: JaizaaTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusTextColor.withOpacity(0.2)),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusTextColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Patient: $patientName  •  Report Date: $displayDate',
                        style: const TextStyle(
                          fontSize: 12,
                          color: JaizaaTheme.textSecondary,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        output,
                        style: const TextStyle(
                          fontSize: 14,
                          color: JaizaaTheme.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _riskColor(String risk) {
    switch (risk) {
      case 'CRITICAL': return JaizaaTheme.criticalRed;
      case 'HIGH': return JaizaaTheme.highWarning;
      case 'MEDIUM': return JaizaaTheme.mediumCaution;
      default: return JaizaaTheme.lowSafe;
    }
  }

  IconData _riskIcon(String risk) {
    switch (risk) {
      case 'CRITICAL': return Icons.error;
      case 'HIGH': return Icons.warning;
      case 'MEDIUM': return Icons.info;
      default: return Icons.check_circle;
    }
  }

  IconData _actionIcon(String type) {
    switch (type) {
      case 'appointment': return Icons.calendar_today;
      case 'alert': return Icons.warning_amber;
      case 'notification': return Icons.message;
      case 'app_record_update': return Icons.update;
      default: return Icons.update;
    }
  }
}
