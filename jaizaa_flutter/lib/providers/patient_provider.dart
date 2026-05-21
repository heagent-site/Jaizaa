import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PatientProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<dynamic> _patients = [];
  List<dynamic> _alerts = [];
  List<dynamic> _history = [];
  bool _isLoading = false;
  bool _isLoadingAlerts = false;
  bool _isLoadingHistory = false;

  List<dynamic> get patients => _patients;
  List<dynamic> get alerts => _alerts;
  List<dynamic> get history => _history;
  bool get isLoading => _isLoading;
  bool get isLoadingAlerts => _isLoadingAlerts;
  bool get isLoadingHistory => _isLoadingHistory;

  Future<void> loadPatients() async {
    _isLoading = true;
    notifyListeners();

    try {
      _patients = await _apiService.getPatients();
    } catch (e) {
      debugPrint("Error loading patients: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAlerts() async {
    _isLoadingAlerts = true;
    notifyListeners();

    try {
      _alerts = await _apiService.getAlerts();
    } catch (e) {
      debugPrint("Error loading alerts: $e");
    } finally {
      _isLoadingAlerts = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    _isLoadingHistory = true;
    notifyListeners();

    try {
      _history = await _apiService.getHistory();
    } catch (e) {
      debugPrint("Error loading history: $e");
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }
}
