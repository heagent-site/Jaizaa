import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/patient_provider.dart';
import '../providers/analysis_provider.dart';
import '../config/theme.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  bool _sortByUrgency = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientProvider>().loadPatients();
    });
  }

  List<dynamic> _getSortedPatients(List<dynamic> patients) {
    if (!_sortByUrgency) return patients;

    final riskOrder = {
      'CRITICAL': 0,
      'HIGH': 1,
      'MEDIUM': 2,
      'LOW': 3,
      'UNKNOWN': 4,
    };

    final sorted = List<dynamic>.from(patients);
    sorted.sort((a, b) {
      final riskA = (a['risk_level'] ?? 'UNKNOWN').toString().toUpperCase();
      final riskB = (b['risk_level'] ?? 'UNKNOWN').toString().toUpperCase();
      return (riskOrder[riskA] ?? 5).compareTo(riskOrder[riskB] ?? 5);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientProvider>();
    final sortedPatients = _getSortedPatients(provider.patients);

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
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: JaizaaTheme.primary))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Patient Records', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: JaizaaTheme.textPrimary)),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          setState(() {
                            _sortByUrgency = !_sortByUrgency;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _sortByUrgency ? JaizaaTheme.primary.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _sortByUrgency ? JaizaaTheme.primary.withOpacity(0.3) : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sort,
                                size: 18,
                                color: _sortByUrgency ? JaizaaTheme.primary : JaizaaTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Urgency',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _sortByUrgency ? JaizaaTheme.primary : JaizaaTheme.textSecondary,
                                ),
                              ),
                              if (_sortByUrgency) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_downward, size: 14, color: JaizaaTheme.primary),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: sortedPatients.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final p = sortedPatients[index];
                      return _buildPatientCard(p);
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/upload');
        },
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
          currentIndex: 1,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: JaizaaTheme.primary,
          unselectedItemColor: JaizaaTheme.textSecondary,
          selectedLabelStyle: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.w500, fontSize: 12),
          onTap: (index) {
            if (index == 0) Navigator.pushReplacementNamed(context, '/');
            if (index == 2) Navigator.pushReplacementNamed(context, '/history');
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

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final riskLevel = patient['risk_level']?.toString().toUpperCase() ?? 'UNKNOWN';
    final followUp = patient['follow_up_status']?.toString() ?? 'None';
    final name = patient['name']?.toString() ?? 'Unknown';
    
    // Determine colors based on risk
    Color stripeColor = JaizaaTheme.lowSafe;
    Color badgeBg = Colors.grey.shade200;
    Color badgeText = Colors.grey.shade800;
    Color avatarBg = Colors.grey.shade200;
    Color avatarText = Colors.grey.shade800;
    IconData statusIcon = Icons.hourglass_empty;
    Color statusColor = JaizaaTheme.textSecondary;
    
    if (riskLevel == 'CRITICAL') {
      stripeColor = JaizaaTheme.criticalRed;
      badgeBg = const Color(0xFFFFDAD6);
      badgeText = const Color(0xFF93000A);
      avatarBg = const Color(0xFFFFDAD6);
      avatarText = const Color(0xFF93000A);
      statusIcon = Icons.notifications_active;
      statusColor = JaizaaTheme.highWarning;
    } else if (riskLevel == 'HIGH') {
      stripeColor = JaizaaTheme.highWarning;
      badgeBg = const Color(0xFFFFF3E0);
      badgeText = JaizaaTheme.highWarning;
      avatarBg = Colors.grey.shade200;
      avatarText = JaizaaTheme.textPrimary;
      statusIcon = Icons.event_available;
      statusColor = JaizaaTheme.primary;
    } else if (riskLevel == 'MEDIUM') {
      stripeColor = JaizaaTheme.mediumCaution;
      badgeBg = const Color(0xFFFFF9C4);
      badgeText = const Color(0xFFF57F17);
      avatarBg = Colors.grey.shade200;
      avatarText = JaizaaTheme.textPrimary;
      statusIcon = Icons.hourglass_empty;
      statusColor = JaizaaTheme.textSecondary;
    }

    // Initials
    String initials = "??";
    final parts = name.split(' ');
    if (parts.length >= 2) {
      initials = "${parts[0][0]}${parts[1][0]}".toUpperCase();
    } else if (name.isNotEmpty) {
      initials = name.substring(0, name.length > 1 ? 2 : 1).toUpperCase();
    }

    return GestureDetector(
      onTap: () async {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
        
        final success = await context
            .read<AnalysisProvider>()
            .loadPatientAnalysis(patient['patient_id'].toString());
        
        if (context.mounted) {
          Navigator.pop(context);
          if (success) {
            Navigator.pushNamed(context, '/results');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'No analysis details found for ${patient['name']}. Please run a new analysis.',
                ),
              ),
            );
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: JaizaaTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: riskLevel == 'CRITICAL' ? JaizaaTheme.criticalRed.withOpacity(0.3) : Colors.grey.shade200),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 4, color: stripeColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: avatarBg,
                          child: Text(initials, style: TextStyle(color: avatarText, fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: JaizaaTheme.textPrimary)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.schedule, size: 14, color: JaizaaTheme.textSecondary),
                                  const SizedBox(width: 4),
                                  const Text('Recently', style: TextStyle(fontSize: 12, color: JaizaaTheme.textSecondary)),
                                  const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('•', style: TextStyle(color: JaizaaTheme.textSecondary))),
                                  Icon(statusIcon, size: 14, color: statusColor),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(followUp, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: badgeText.withOpacity(0.2)),
                          ),
                          child: Text(
                            riskLevel,
                            style: TextStyle(color: badgeText, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                          ),
                          child: const Icon(Icons.chevron_right, color: JaizaaTheme.primary),
                        ),
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
