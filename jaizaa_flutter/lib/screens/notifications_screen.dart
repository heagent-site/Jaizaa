import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/patient_provider.dart';
import '../providers/analysis_provider.dart';
import '../config/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientProvider>().loadAlerts();
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
          icon: const Icon(Icons.arrow_back, color: JaizaaTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: JaizaaTheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.notifications, color: JaizaaTheme.primary),
              if (provider.alerts.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: JaizaaTheme.criticalRed,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${provider.alerts.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: provider.isLoadingAlerts
          ? const Center(child: CircularProgressIndicator(color: JaizaaTheme.primary))
          : provider.alerts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Alerts from patient analyses will appear here.',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Active Alerts',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: JaizaaTheme.criticalRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${provider.alerts.length} ALERT${provider.alerts.length != 1 ? 'S' : ''}',
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: JaizaaTheme.criticalRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.alerts.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final alert = provider.alerts[index];
                          return _buildNotificationCard(alert);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toUpperCase()) {
      case 'CRITICAL':
        return JaizaaTheme.criticalRed;
      case 'HIGH':
        return JaizaaTheme.highWarning;
      case 'MEDIUM':
        return JaizaaTheme.mediumCaution;
      case 'LOW':
      default:
        return JaizaaTheme.lowSafe;
    }
  }

  IconData _getUrgencyIcon(String urgency) {
    switch (urgency.toUpperCase()) {
      case 'CRITICAL':
        return Icons.error;
      case 'HIGH':
        return Icons.warning_amber;
      case 'MEDIUM':
        return Icons.info_outline;
      default:
        return Icons.check_circle_outline;
    }
  }

  Widget _buildNotificationCard(Map<String, dynamic> alert) {
    final urgency = (alert['urgency_level'] ?? 'MEDIUM').toString().toUpperCase();
    final riskColor = _getUrgencyColor(urgency);
    final patientName = alert['patient_name'] ?? 'Unknown';
    final pattern = alert['clinical_pattern'] ?? 'Clinical Alert';
    final message = alert['message'] ?? '';
    final createdAt = alert['created_at']?.toString() ?? '';
    final dateStr = createdAt.length >= 10 ? createdAt.substring(0, 10) : '';

    return GestureDetector(
      onTap: () async {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        final success = await context
            .read<AnalysisProvider>()
            .loadPatientAnalysis(alert['patient_id'].toString());

        if (context.mounted) {
          Navigator.pop(context); // dismiss loading
          if (success) {
            Navigator.pushNamed(context, '/results');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No analysis found for $patientName.')),
            );
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: JaizaaTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: riskColor.withOpacity(0.3)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color strip at top
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: riskColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_getUrgencyIcon(urgency), color: riskColor, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pattern,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: riskColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          urgency,
                          style: TextStyle(
                            color: riskColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'JetBrains Mono',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey.shade200,
                        child: Text(
                          _getInitials(patientName),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: JaizaaTheme.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(patientName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            Text('Patient ID: #${alert['patient_id']}', style: const TextStyle(fontSize: 11, color: JaizaaTheme.textSecondary, fontFamily: 'JetBrains Mono')),
                          ],
                        ),
                      ),
                      Text(dateStr, style: const TextStyle(fontSize: 11, color: JaizaaTheme.textSecondary, fontFamily: 'JetBrains Mono')),
                    ],
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: riskColor.withOpacity(0.1)),
                      ),
                      child: Text(
                        message,
                        style: const TextStyle(fontSize: 13, height: 1.4, color: JaizaaTheme.textPrimary),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(child: CircularProgressIndicator()),
                          );
                          final success = await context
                              .read<AnalysisProvider>()
                              .loadPatientAnalysis(alert['patient_id'].toString());
                          if (context.mounted) {
                            Navigator.pop(context);
                            if (success) {
                              Navigator.pushNamed(context, '/results');
                            }
                          }
                        },
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('VIEW DETAILS', style: TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          foregroundColor: JaizaaTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name.substring(0, name.length > 1 ? 2 : 1).toUpperCase();
    }
    return '??';
  }
}
