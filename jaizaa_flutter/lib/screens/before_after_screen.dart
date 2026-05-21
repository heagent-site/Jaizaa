import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analysis_provider.dart';
import '../config/theme.dart';

class BeforeAfterScreen extends StatelessWidget {
  const BeforeAfterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final report = context.watch<AnalysisProvider>().fullResult?['report'];
    if (report == null) {
      return const Scaffold(body: Center(child: Text("No result data")));
    }

    final before = report['before'];
    final after = report['after'];

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
          child: Text(
            'Jaizaa',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: JaizaaTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: JaizaaTheme.textSecondary),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Success Message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: JaizaaTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: JaizaaTheme.primary.withOpacity(0.2)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: JaizaaTheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Update Successful', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: JaizaaTheme.textPrimary)),
                        const SizedBox(height: 4),
                        Text("Patient records for ${before['name'] ?? 'the patient'} have been updated and synced.", style: const TextStyle(fontSize: 14, color: JaizaaTheme.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Comparison Card
            Container(
              decoration: BoxDecoration(
                color: JaizaaTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Card Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('State Comparison', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: JaizaaTheme.textPrimary)),
                            const SizedBox(height: 4),
                            Text("Patient Name: ${before['name'] ?? 'Unknown'}", style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: JaizaaTheme.textSecondary)),
                          ],
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                          child: const Icon(Icons.compare_arrows, color: JaizaaTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  
                  // Table Header
                  Container(
                    color: Colors.grey.shade100,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: const Row(
                      children: [
                        Expanded(flex: 2, child: Text('FIELD', style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, fontWeight: FontWeight.bold, color: JaizaaTheme.textSecondary))),
                        Expanded(flex: 2, child: Text('BEFORE', style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, fontWeight: FontWeight.bold, color: JaizaaTheme.textSecondary))),
                        Expanded(flex: 2, child: Text('AFTER', style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, fontWeight: FontWeight.bold, color: JaizaaTheme.textSecondary))),
                      ],
                    ),
                  ),
                  
                  // Table Rows
                  _buildTableRow(
                    'Risk Level',
                    _buildRiskPill(before['risk_level']?.toString()),
                    _buildRiskPill(after['risk_level']?.toString()),
                  ),
                  _buildTableRow(
                    'Follow-up',
                    _buildFollowUpPill(before['follow_up_status']?.toString()),
                    _buildFollowUpPill(after['follow_up_status']?.toString()),
                  ),
                  _buildTableRow(
                    'Care Gap',
                    _buildCareGapPill(before['care_gap']?.toString()),
                    _buildCareGapPill(after['care_gap']?.toString()),
                  ),
                  _buildTableRow(
                    'Dr. Awareness',
                    _buildDoctorAwarenessPill(before['doctor_awareness']?.toString()),
                    _buildDoctorAwarenessPill(after['doctor_awareness']?.toString()),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<AnalysisProvider>().clear();
                  Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: JaizaaTheme.primary,
                  foregroundColor: JaizaaTheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.dashboard),
                label: const Text('BACK TO DASHBOARD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(String field, Widget beforeWidget, Widget afterWidget) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(field, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: JaizaaTheme.textPrimary))),
          Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: beforeWidget)),
          Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: afterWidget)),
        ],
      ),
    );
  }

  Widget _buildPill(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskPill(String? val) {
    final clean = val?.toUpperCase() ?? 'UNKNOWN';
    IconData icon = Icons.help;
    Color color = Colors.grey;
    if (clean == 'CRITICAL') {
      icon = Icons.error;
      color = JaizaaTheme.criticalRed;
    } else if (clean == 'HIGH') {
      icon = Icons.warning;
      color = JaizaaTheme.highWarning;
    } else if (clean == 'MEDIUM') {
      icon = Icons.info;
      color = JaizaaTheme.mediumCaution;
    } else if (clean == 'LOW') {
      icon = Icons.check_circle;
      color = JaizaaTheme.lowSafe;
    }
    return _buildPill(clean, icon, color);
  }

  Widget _buildFollowUpPill(String? val) {
    final clean = val?.toUpperCase() ?? 'NONE';
    IconData icon = Icons.close;
    Color color = JaizaaTheme.criticalRed;
    if (clean != 'NONE') {
      icon = Icons.event_available;
      color = JaizaaTheme.primary;
    }
    return _buildPill(clean, icon, color);
  }

  Widget _buildCareGapPill(String? val) {
    final clean = val?.toUpperCase() ?? 'OPEN';
    IconData icon = Icons.error;
    Color color = JaizaaTheme.criticalRed;
    if (clean == 'CLOSED') {
      icon = Icons.check_circle;
      color = JaizaaTheme.primary;
    }
    return _buildPill(clean, icon, color);
  }

  Widget _buildDoctorAwarenessPill(String? val) {
    final clean = val?.toUpperCase() ?? 'UNAWARE';
    IconData icon = Icons.notifications_off;
    Color color = JaizaaTheme.criticalRed;
    if (clean == 'ALERTED') {
      icon = Icons.notifications_active;
      color = JaizaaTheme.primary;
    }
    return _buildPill(clean, icon, color);
  }
}
