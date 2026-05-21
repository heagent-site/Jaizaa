import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/analysis_provider.dart';
import 'providers/patient_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => AnalysisProvider()),
      ],
      child: const JaizaaApp(),
    ),
  );
}
