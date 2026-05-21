import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/patient_provider.dart';
import '../providers/analysis_provider.dart';
import '../config/theme.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientProvider>().loadPatients();
      context.read<PatientProvider>().loadAlerts();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JaizaaTheme.background,
      appBar: AppBar(
        backgroundColor: JaizaaTheme.surface,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.description_outlined, color: JaizaaTheme.primary),
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
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: JaizaaTheme.primary),
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: JaizaaTheme.criticalRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Analyze New Report Button
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: JaizaaTheme.primary,
                foregroundColor: JaizaaTheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 1,
              ),
              icon: const Icon(Icons.add),
              label: const Text('ANALYZE NEW REPORT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
            const SizedBox(height: 24),
            
            // Bento Stats Grid (Dynamic)
            Consumer<PatientProvider>(
              builder: (context, provider, child) {
                final totalPatients = provider.patients.length;
                final highRiskPatients = provider.patients.where((p) => p['risk_level'] == 'CRITICAL' || p['risk_level'] == 'HIGH').length;
                final alertCount = provider.alerts.length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCardMain(totalPatients.toString(), 'Total Patients', Icons.people),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCardAlert(highRiskPatients.toString(), 'High Risk', alertCount.toString()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Active Alerts Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Active Alerts',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/patients');
                          },
                          child: Text(
                            'VIEW ALL (${provider.alerts.length})',
                            style: const TextStyle(color: JaizaaTheme.primary, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (provider.isLoadingAlerts)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (provider.alerts.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Text(
                            'No active alerts at the moment.',
                            style: TextStyle(color: JaizaaTheme.textSecondary, fontFamily: 'JetBrains Mono'),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.alerts.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final alert = provider.alerts[index];
                          final urgency = alert['urgency_level'] ?? 'MEDIUM';
                          final riskColor = _getUrgencyColor(urgency);
                          return _buildAlertCard(
                            patientName: alert['patient_name'] ?? 'Unknown',
                            patientInfo: 'Patient ID: #${alert['patient_id']}',
                            riskLevel: urgency,
                            riskColor: riskColor,
                            alertTitle: alert['clinical_pattern'] ?? 'Clinical Pattern',
                            alertMainVal: alert['message'] ?? '',
                            alertSubVal: alert['created_at'] != null && alert['created_at'].toString().length >= 10
                                ? alert['created_at'].toString().substring(0, 10)
                                : '',
                            showDismiss: false,
                            onReview: () async {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                              
                              final success = await context
                                  .read<AnalysisProvider>()
                                  .loadPatientAnalysis(alert['patient_id'].toString());
                              
                              if (context.mounted) {
                                Navigator.pop(context);
                                if (success) {
                                  Navigator.pushNamed(context, '/results');
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'No analysis details found for ${alert['patient_name']}. Please run an analysis.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: JaizaaTheme.surface,
          selectedItemColor: JaizaaTheme.primary,
          unselectedItemColor: JaizaaTheme.textSecondary,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            if (index == 1) Navigator.pushReplacementNamed(context, '/patients');
            if (index == 2) Navigator.pushReplacementNamed(context, '/history');
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Patients'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          ],
        ),
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

  Widget _buildStatCardMain(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JaizaaTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: const TextStyle(fontFamily: 'JetBrains Mono', color: JaizaaTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: JaizaaTheme.primary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: JaizaaTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: JaizaaTheme.primary, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardAlert(String value, String label, String badgeValue) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JaizaaTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.warning, color: JaizaaTheme.criticalRed),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: JaizaaTheme.criticalRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$badgeValue NEW', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label.toUpperCase(), style: const TextStyle(fontFamily: 'JetBrains Mono', color: JaizaaTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatCardAction(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JaizaaTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: JaizaaTheme.secondary),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label.toUpperCase(), style: const TextStyle(fontFamily: 'JetBrains Mono', color: JaizaaTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAlertCard({
    required String patientName,
    required String patientInfo,
    required String riskLevel,
    required Color riskColor,
    required String alertTitle,
    required String alertMainVal,
    required String alertSubVal,
    required bool showDismiss,
    Color? titleColor,
    required VoidCallback onReview,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: JaizaaTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: riskColor.withOpacity(0.5)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(patientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          Text(patientInfo, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: JaizaaTheme.textSecondary), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: riskColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(riskLevel.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: JaizaaTheme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: riskColor.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alertTitle, style: TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold, color: titleColor ?? JaizaaTheme.criticalRed, fontSize: 12), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              alertMainVal,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              softWrap: true,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(alertSubVal, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: JaizaaTheme.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (showDismiss) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('DISMISS', style: TextStyle(fontFamily: 'JetBrains Mono', color: JaizaaTheme.textPrimary)),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: JaizaaTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('REVIEW', style: TextStyle(fontFamily: 'JetBrains Mono', color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
