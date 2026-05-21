import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/home_dashboard.dart';
import 'screens/upload_screen.dart';
import 'screens/processing_screen.dart';
import 'screens/results_screen.dart';
import 'screens/execution_screen.dart';
import 'screens/before_after_screen.dart';
import 'screens/patient_list_screen.dart';
import 'screens/history_screen.dart';
import 'screens/notifications_screen.dart';

class JaizaaApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  const JaizaaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jaizaa',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: JaizaaTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeDashboard(),
        '/upload': (context) => const UploadScreen(),
        '/processing': (context) => const ProcessingScreen(),
        '/results': (context) => const ResultsScreen(),
        '/execution': (context) => const ExecutionScreen(),
        '/before_after': (context) => const BeforeAfterScreen(),
        '/patients': (context) => const PatientListScreen(),
        '/history': (context) => const HistoryScreen(),
        '/notifications': (context) => const NotificationsScreen(),
      },
    );
  }
}
