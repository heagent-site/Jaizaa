/// API configuration for the Jaizaa backend.
///
/// The actual URL resolution happens at runtime inside [ApiService]
/// via a /health probe cascade:
///   1. --dart-define=API_BASE_URL (CI / custom APK build)
///   2. https://heagent-jaizaa.hf.space  (HF production)
///   3. http://192.168.100.95:8000        (same-WiFi local)
///   4. http://localhost:8000             (local dev)
///
/// This file is kept for any place in the codebase that needs a
/// compile-time constant (e.g., deep-link schemes, logging labels).
class ApiConfig {
  /// The Hugging Face production base URL.
  static const String productionUrl = 'https://heagent-jaizaa.hf.space';

  /// Local network URL (PC on same WiFi as phone).
  static const String localNetworkUrl = 'http://192.168.100.95:8000';

  /// localhost for desktop/web dev.
  static const String localhostUrl = 'http://localhost:8000';
}
