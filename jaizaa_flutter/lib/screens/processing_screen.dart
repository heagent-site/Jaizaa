import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analysis_provider.dart';
import '../config/theme.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> with TickerProviderStateMixin {
  final List<String> _logs = [];
  final List<String> _doneAgents = [];
  late AnimationController _pulseController;
  late AnimationController _spinController;
  bool _isComplete = false;

  final List<Map<String, dynamic>> agents = [
    {"id": "Document Reader", "desc": "Extracting biometrics..."},
    {"id": "Clinical Analyzer", "desc": "Identifying patterns..."},
    {"id": "Risk Assessor", "desc": "Calculating risk profile..."},
    {"id": "Action Planner", "desc": "Formulating care plan..."},
    {"id": "Execution Agent", "desc": "Validating guidelines..."},
    {"id": "Outcome Reporter", "desc": "Generating summary..."},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnalysis();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  void _startAnalysis() async {
    final provider = context.read<AnalysisProvider>();
    // Add initial log
    setState(() {
      _logs.add('Initializing clinical analysis pipeline...');
    });
    
    try {
      bool success = await provider.analyze();
      
      if (success && mounted) {
        final result = provider.fullResult;
        if (result == null) {
          throw Exception("Analysis succeeded but fullResult is null in provider");
        }
        
        final report = result['report'];
        if (report == null) {
          throw Exception("Analysis result is missing 'report' key");
        }
        
        final trace = report['agent_trace'];
        if (trace == null) {
          throw Exception("Analysis result 'report' is missing 'agent_trace' key");
        }
        
        if (trace is! List) {
          throw Exception("agent_trace is not a List (found ${trace.runtimeType})");
        }
        
        for (int i = 0; i < trace.length; i++) {
          final step = trace[i];
          if (step is! Map) {
            continue;
          }
          await Future.delayed(const Duration(milliseconds: 1200));
          if (mounted) {
            setState(() {
              if (i > 0 && trace[i - 1] is Map) {
                _doneAgents.add(trace[i - 1]['agent']?.toString() ?? '');
              }
              _logs.add('[${step['agent'] ?? 'Agent'}] ${step['key_output'] ?? 'Processing...'}');
            });
          }
        }
        
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          setState(() {
            if (trace.isNotEmpty && trace.last is Map) {
              _doneAgents.add(trace.last['agent']?.toString() ?? '');
            }
            // If the trace didn't cover all 6, just mark all done for UI completeness
            for (var a in agents) {
              if (!_doneAgents.contains(a['id'])) _doneAgents.add(a['id']);
            }
            _logs.add('Analysis complete. Preparing results UI.');
            _isComplete = true;
          });
        }
      } else if (!success && mounted) {
        setState(() {
          _logs.add('ERROR: Analysis failed (API error or empty response).');
          _isComplete = true;
        });
      }
    } catch (e, stackTrace) {
      debugPrint("Error during _startAnalysis UI execution: $e\n$stackTrace");
      if (mounted) {
        setState(() {
          _logs.add('ERROR: $e');
          // For UI completeness on error, stop spinning and allow viewing whatever we got
          _isComplete = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = (_doneAgents.length / agents.length).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: JaizaaTheme.background,
      appBar: AppBar(
        backgroundColor: JaizaaTheme.surface,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.description, color: JaizaaTheme.primary),
          onPressed: () {},
        ),
        title: Text(
          'Jaizaa',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: JaizaaTheme.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: JaizaaTheme.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            // Header
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Opacity(
                  opacity: _isComplete ? 1.0 : 0.6 + (_pulseController.value * 0.4),
                  child: Text(
                    _isComplete ? 'Analysis Complete' : 'Analyzing Report...',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: _isComplete ? JaizaaTheme.primary : JaizaaTheme.textPrimary,
                        ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Processing clinical data via 6 specialized agents.',
              style: TextStyle(fontSize: 16, color: JaizaaTheme.textSecondary),
            ),
            const SizedBox(height: 24),

            // Progress Bar
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(JaizaaTheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Agent List
            Expanded(
              child: ListView.separated(
                itemCount: agents.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final agent = agents[index];
                  final isDone = _doneAgents.contains(agent['id']);
                  final isRunning = !isDone && (_doneAgents.length == index);
                  
                  return _buildAgentCard(
                    index + 1,
                    agent['id'],
                    isDone ? 'Completed' : (isRunning ? agent['desc'] : 'Pending'),
                    isDone,
                    isRunning,
                  );
                },
              ),
            ),
            
            if (_isComplete)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/results'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JaizaaTheme.primary,
                    foregroundColor: JaizaaTheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  icon: const Text('VIEW RESULTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  label: const Icon(Icons.arrow_forward),
                ),
              ),

            // Live Log Feed
            Container(
              height: 120,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: JaizaaTheme.traceBackground,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.terminal, color: JaizaaTheme.traceText, size: 16),
                      const SizedBox(width: 8),
                      Text('LIVE TRACE', style: JaizaaTheme.traceStyle.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      reverse: true, // Auto-scroll behavior
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        // Reverse index
                        final logIndex = _logs.length - 1 - index;
                        final isLatest = logIndex == _logs.length - 1 && !_isComplete;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: isLatest
                            ? AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Container(
                                    padding: const EdgeInsets.only(left: 8),
                                    decoration: const BoxDecoration(
                                      border: Border(left: BorderSide(color: JaizaaTheme.secondary, width: 2)),
                                    ),
                                    child: Text(
                                      '${_logs[logIndex]}${_pulseController.value > 0.5 ? "_" : " "}',
                                      style: JaizaaTheme.traceStyle.copyWith(color: Colors.white),
                                    ),
                                  );
                                },
                              )
                            : Text(
                                _logs[logIndex],
                                style: JaizaaTheme.traceStyle.copyWith(color: Colors.white.withOpacity(0.7)),
                              ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentCard(int stepNum, String title, String desc, bool isDone, bool isRunning) {
    Color bgColor = JaizaaTheme.surface;
    Color borderColor = Colors.grey.shade300;
    Widget icon;
    
    if (isDone) {
      bgColor = JaizaaTheme.surface;
      icon = Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: JaizaaTheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_circle, color: JaizaaTheme.primary, size: 20),
      );
    } else if (isRunning) {
      bgColor = JaizaaTheme.secondary.withOpacity(0.05);
      borderColor = JaizaaTheme.secondary.withOpacity(0.3);
      icon = RotationTransition(
        turns: _spinController,
        child: const Icon(Icons.sync, color: JaizaaTheme.secondary, size: 28),
      );
    } else {
      bgColor = Colors.grey.shade50;
      icon = const Icon(Icons.hourglass_empty, color: Colors.grey, size: 24);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, style: isDone || isRunning ? BorderStyle.solid : BorderStyle.solid),
        boxShadow: isRunning ? [BoxShadow(color: JaizaaTheme.secondary.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))] : null,
      ),
      child: Row(
        children: [
          if (isRunning)
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(color: JaizaaTheme.secondary, borderRadius: BorderRadius.circular(2)),
              margin: const EdgeInsets.only(right: 12),
            ),
          icon,
          SizedBox(width: isRunning ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$stepNum. $title',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isRunning ? FontWeight.bold : FontWeight.w500,
                    color: isDone || isRunning ? JaizaaTheme.textPrimary : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: isRunning ? 0.6 + (_pulseController.value * 0.4) : 1.0,
                      child: Text(
                        desc,
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12,
                          color: isRunning ? JaizaaTheme.secondary : Colors.grey.shade600,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
