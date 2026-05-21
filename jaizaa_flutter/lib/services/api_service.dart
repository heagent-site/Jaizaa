import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../app.dart';

/// Resolves the backend base URL at runtime.
///
/// Priority order:
///   1. Compile-time --dart-define=API_BASE_URL (set during CI/APK build)
///   2. https://heagent-jaizaa.hf.space   (HF production)
///   3. http://192.168.100.95:8000          (same-WiFi local)
///   4. http://localhost:8000               (local dev fallback)
class ApiService {
  static const _candidates = [
    String.fromEnvironment('API_BASE_URL', defaultValue: ''),
    'https://heagent-jaizaa.hf.space',
    'http://192.168.100.95:8000',
    'http://localhost:8000',
  ];

  // Shared singleton Dio instance — resolved lazily on first call.
  Dio? _dio;

  // Resolved URL cached after first successful health-check.
  static String? _resolvedBaseUrl;

  /// Returns a Dio client connected to the first reachable backend.
  Future<Dio> _client() async {
    if (_dio != null) return _dio!;

    // If already resolved in a previous call (same session), reuse it.
    if (_resolvedBaseUrl != null) {
      _dio = _buildDio(_resolvedBaseUrl!);
      return _dio!;
    }

    for (final candidate in _candidates) {
      if (candidate.isEmpty) continue;
      try {
        final probe = Dio(BaseOptions(
          baseUrl: candidate,
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ));
        await probe.get('/health');
        _resolvedBaseUrl = candidate;
        print('[ApiService] Connected to: $candidate');
        _dio = _buildDio(candidate);
        return _dio!;
      } catch (_) {
        print('[ApiService] [INFO] Unreachable: $candidate — trying next…');
      }
    }

    // All candidates failed — use the HF URL anyway so error messages
    // are meaningful (rather than crashing with a null/empty base URL).
    _resolvedBaseUrl = 'https://heagent-jaizaa.hf.space';
    print('[ApiService] [INFO] All candidates failed. Defaulting to HF Space.');
    _dio = _buildDio(_resolvedBaseUrl!);
    return _dio!;
  }

  Dio _buildDio(String baseUrl) => Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 120),
      ));

  // ─── Public API ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> analyzeReport(
      List<int> fileBytes, String fileName, String patientId) async {
    try {
      final dio = await _client();
      final formData = FormData.fromMap({
        'patient_id': patientId,
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });
      final response = await dio.post('/analyze', data: formData);
      return response.data;
    } on DioException catch (e) {
      debugPrint('[ApiService] analyzeReport error: ${e.message}');
      
      final response = e.response;
      final statusCode = response?.statusCode;
      final data = response?.data;
      String? errorMessage;
      if (data is Map) {
        errorMessage = data['detail']?.toString() ?? data['message']?.toString();
      } else {
        errorMessage = data?.toString();
      }

      final isCreditError = statusCode == 402 || 
                            (errorMessage != null && (
                              errorMessage.contains('402') || 
                              errorMessage.toLowerCase().contains('credit') || 
                              errorMessage.toLowerCase().contains('afford') ||
                              errorMessage.toLowerCase().contains('insufficient')
                            ));

      if (isCreditError) {
        _showErrorDialog(
          'Insufficient Credits',
          'Analysis failed: insufficient API credits. Please try again.',
        );
      } else if (statusCode == 500) {
        _showErrorDialog(
          'Server Error',
          'An unexpected server error occurred. Please try again.',
        );
      } else {
        _showErrorDialog(
          'Analysis Failed',
          errorMessage ?? 'Connection to server failed. Please try again.',
        );
      }
      rethrow;
    }
  }

  void _showErrorDialog(String title, String message) {
    final context = JaizaaApp.navigatorKey.currentContext;
    if (context == null) {
      debugPrint('[ApiService] Cannot show dialog, context is null');
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                title.toLowerCase().contains('credit') || title.toLowerCase().contains('insufficient')
                    ? Icons.monetization_on
                    : Icons.error_outline,
                color: Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<dynamic>> getPatients() async {
    try {
      final dio = await _client();
      final response = await dio.get('/patients');
      return response.data;
    } on DioException catch (e) {
      debugPrint('[ApiService] getPatients error: ${e.message}');
      return [];
    }
  }

  Future<Map<String, dynamic>> createPatient(
      String name, String phone) async {
    try {
      final dio = await _client();
      final response = await dio.post('/patients', data: {
        'name': name,
        'phone': phone,
      });
      return response.data;
    } on DioException catch (e) {
      debugPrint('[ApiService] createPatient error: ${e.message}');
      rethrow;
    }
  }

  Future<List<dynamic>> getAlerts() async {
    try {
      final dio = await _client();
      final response = await dio.get('/alerts');
      return response.data;
    } on DioException catch (e) {
      debugPrint('[ApiService] getAlerts error: ${e.message}');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getPatient(String patientId) async {
    try {
      final dio = await _client();
      final response = await dio.get('/patients/$patientId');
      return response.data;
    } on DioException catch (e) {
      debugPrint('[ApiService] getPatient error: ${e.message}');
      return null;
    }
  }

  Future<List<dynamic>> getHistory() async {
    try {
      final dio = await _client();
      final response = await dio.get('/history');
      return response.data;
    } on DioException catch (e) {
      debugPrint('[ApiService] getHistory error: ${e.message}');
      return [];
    }
  }
}
