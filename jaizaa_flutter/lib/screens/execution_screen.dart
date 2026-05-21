import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analysis_provider.dart';
import '../config/theme.dart';

class ExecutionScreen extends StatefulWidget {
  const ExecutionScreen({super.key});

  @override
  State<ExecutionScreen> createState() => _ExecutionScreenState();
}

class _ExecutionScreenState extends State<ExecutionScreen> with TickerProviderStateMixin {
  final List<String> _completed = [];
  bool _allDone = false;
  List<Map<String, dynamic>> _actions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AnalysisProvider>();
      final rawActions = provider.fullResult?['action_plan'];
      final List<dynamic> actionsList = rawActions is List ? rawActions : (rawActions?['action_plan'] ?? rawActions?['data'] ?? []);
      
      setState(() {
        _actions = actionsList.map((a) => <String, dynamic>{
          'id': a['action_type'] ?? 'unknown',
          'title': (a['action_type'] == 'app_record_update') ? 'PATIENT RECORD UPDATE' : a['action_type'].toString().toUpperCase(),
          'subtitle': 'Priority: ${a["priority"]}',
          'type': a['action_type'] == 'notification' ? 'whatsapp' : (a['action_type'] == 'alert' ? 'risk_badge' : 'normal'),
          'raw': a,
        }).toList().cast<Map<String, dynamic>>();
      });

      _revealActions();
    });
  }

  void _revealActions() async {
    for (final action in _actions) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) setState(() => _completed.add(action['id']));
    }
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _allDone = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JaizaaTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            children: [
              // Header
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _allDone ? Icons.task_alt : Icons.sync,
                        color: JaizaaTheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _allDone ? 'Execution Complete' : 'Executing Actions...',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: JaizaaTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Applying clinical interventions based on risk assessment.',
                    style: TextStyle(fontSize: 16, color: JaizaaTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Action Feed
              Expanded(
                child: ListView.separated(
                  itemCount: _actions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final action = _actions[index];
                    final isDone = _completed.contains(action['id']);
                    
                    if (!isDone) return const SizedBox.shrink();

                    return _buildAnimatedCard(
                      child: _buildActionCard(action),
                    );
                  },
                ),
              ),

              // Bottom Button
              if (_allDone)
                _buildAnimatedCard(
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/before_after'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: JaizaaTheme.primary,
                        foregroundColor: JaizaaTheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.compare_arrows),
                      label: const Text('VIEW BEFORE/AFTER COMPARISON', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard({required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, childWidget) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: childWidget,
          ),
        );
      },
      child: child,
    );
  }

  Color _urgencyColor(String urgency) {
    switch (urgency.toUpperCase()) {
      case 'URGENT':
      case 'CRITICAL':
        return JaizaaTheme.criticalRed;
      case 'HIGH':
        return JaizaaTheme.highWarning;
      case 'MEDIUM':
        return JaizaaTheme.mediumCaution;
      default:
        return JaizaaTheme.lowSafe;
    }
  }

  Widget _buildPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action) {
    final raw = action['raw'] ?? {};
    
    if (action['type'] == 'whatsapp') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE1F5FE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF81D4FA)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.chat, color: JaizaaTheme.secondary, size: 20),
                const SizedBox(width: 8),
                Text(action['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: JaizaaTheme.secondary)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
              ),
              width: double.infinity,
              child: Text(
                raw['message_text'] ?? '',
                style: const TextStyle(fontSize: 15, color: JaizaaTheme.textPrimary, height: 1.5),
              ),
            ),
          ],
        ),
      );
    }

    if (action['type'] == 'risk_badge') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: JaizaaTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: JaizaaTheme.criticalRed.withOpacity(0.3)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, color: JaizaaTheme.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(action['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: JaizaaTheme.textPrimary)),
                  const SizedBox(height: 8),
                  Text(raw['message'] ?? '', style: const TextStyle(fontSize: 14, color: JaizaaTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Risk Level:', style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: JaizaaTheme.textSecondary)),
                      const SizedBox(width: 8),
                      _buildPill(raw['urgency_level'] ?? 'HIGH', _urgencyColor(raw['urgency_level'] ?? 'HIGH')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (action['id'] == 'appointment') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: JaizaaTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, color: JaizaaTheme.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("APPOINTMENT SCHEDULED", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: JaizaaTheme.primary, fontFamily: 'JetBrains Mono')),
                  const SizedBox(height: 8),
                  Text("Specialty: ${raw['specialty'] ?? 'General'}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: JaizaaTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text("Slot: ${raw['scheduled_slot'] ?? 'TBD'}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: JaizaaTheme.textPrimary)),
                  if (raw['reason'] != null && raw['reason'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(raw['reason'], style: const TextStyle(fontSize: 14, color: JaizaaTheme.textSecondary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (action['id'] == 'app_record_update') {
      final updates = raw['updates'] ?? {};
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: JaizaaTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, color: JaizaaTheme.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("PATIENT RECORD UPDATED", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: JaizaaTheme.primary, fontFamily: 'JetBrains Mono')),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPill('Risk: ${updates['risk_level'] ?? 'UNKNOWN'}', JaizaaTheme.criticalRed),
                      _buildPill('Follow-up: ${updates['follow_up_status'] ?? 'NONE'}', JaizaaTheme.primary),
                      _buildPill('Care Gap: ${updates['care_gap'] ?? 'OPEN'}', JaizaaTheme.secondary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JaizaaTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: JaizaaTheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: JaizaaTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(action['subtitle'], style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: JaizaaTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
