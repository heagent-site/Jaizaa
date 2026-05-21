import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AnalysisProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // Per-patient result cache keyed by patient_id
  final Map<String, Map<String, dynamic>> _patientResults = {};
  
  bool _isAnalyzing = false;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  String? _selectedPatientId;

  // Per-action approval state: key = "patientId_actionIndex"
  final Map<String, bool> _approvedActions = {};

  Map<String, dynamic>? get fullResult {
    if (_selectedPatientId != null && _patientResults.containsKey(_selectedPatientId)) {
      return _patientResults[_selectedPatientId];
    }
    return null;
  }

  bool get isAnalyzing => _isAnalyzing;
  String? get selectedFileName => _selectedFileName;
  String? get selectedPatientId => _selectedPatientId;

  bool isActionApproved(int actionIndex) {
    final key = '${_selectedPatientId}_$actionIndex';
    return _approvedActions[key] ?? false;
  }

  void toggleActionApproval(int actionIndex) {
    final key = '${_selectedPatientId}_$actionIndex';
    _approvedActions[key] = !(_approvedActions[key] ?? false);
    notifyListeners();
  }

  int get approvedCount {
    if (_selectedPatientId == null) return 0;
    return _approvedActions.entries
        .where((e) => e.key.startsWith('${_selectedPatientId}_') && e.value)
        .length;
  }

  void setFile(Uint8List bytes, String fileName) {
    _selectedFileBytes = bytes;
    _selectedFileName = fileName;
    notifyListeners();
  }

  void setPatient(String id) {
    _selectedPatientId = id;
    notifyListeners();
  }

  /// Clear only per-patient approval states before a new analysis run.
  /// Does NOT clear the file bytes — those are needed by analyze().
  void resetApprovalsForPatient(String patientId) {
    _approvedActions.removeWhere((key, _) => key.startsWith('${patientId}_'));
    notifyListeners();
  }

  /// Full reset: call this only after navigating away from results.
  void resetForNewAnalysis() {
    _selectedFileBytes = null;
    _selectedFileName = null;
    if (_selectedPatientId != null) {
      _approvedActions.removeWhere((key, _) => key.startsWith('${_selectedPatientId}_'));
    }
    notifyListeners();
  }

  Future<bool> analyze() async {
    if (_selectedFileBytes == null || _selectedPatientId == null) return false;

    _isAnalyzing = true;
    Future.microtask(() => notifyListeners());

    try {
      final rawResult = await _apiService.analyzeReport(_selectedFileBytes!, _selectedFileName!, _selectedPatientId!);
      final decoded = rawResult is String ? jsonDecode(rawResult as String) : rawResult;
      _patientResults[_selectedPatientId!] = Map<String, dynamic>.from(decoded);
      // Clear approval states for this patient since we have new results
      _approvedActions.removeWhere((key, _) => key.startsWith('${_selectedPatientId}_'));
      return true;
    } catch (e) {
      debugPrint("Error analyzing: $e");
      return false;
    } finally {
      _isAnalyzing = false;
      Future.microtask(() => notifyListeners());
    }
  }

  Future<bool> loadPatientAnalysis(String patientId) async {
    // Always fetch fresh from API — never serve stale in-memory cache
    // (different patients may have been analyzed since last fetch)
    _isAnalyzing = true;
    notifyListeners();
    try {
      final patient = await _apiService.getPatient(patientId);
      if (patient != null && patient['last_analysis_result'] != null) {
        final rawResult = patient['last_analysis_result'];
        final decoded = rawResult is String ? jsonDecode(rawResult as String) : rawResult;
        // Store fresh result keyed by patient_id (overwrites any stale cached value)
        _patientResults[patientId] = Map<String, dynamic>.from(decoded);
        _selectedPatientId = patientId;
        debugPrint('[Analysis] Loaded fresh result for patient $patientId: '
            '${decoded['risk']?['overall_risk'] ?? 'unknown risk'}');
        return true;
      }
      debugPrint('[Analysis] No analysis result found for patient $patientId');
      return false;
    } catch (e) {
      debugPrint('[Analysis] Error loading patient $patientId: $e');
      return false;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }


  void clear() {
    _patientResults.clear();
    _selectedFileBytes = null;
    _selectedFileName = null;
    _selectedPatientId = null;
    _isAnalyzing = false;
    _approvedActions.clear();
    notifyListeners();
  }
}
