import 'package:flutter/foundation.dart';

/// Konfigurasi koneksi ke backend Laravel SakuraKotoba.
///
/// Mendukung live production di `https://fib.ordr.my.id`, web auto-origin,
/// Android emulator, dan manual override via `--dart-define=API_URL=...`.
class AppConfig {
  static const String _defined = String.fromEnvironment('API_URL');
  static const String liveProductionUrl = 'https://fib.ordr.my.id';

  static String get baseUrl {
    if (_defined.isNotEmpty) return _defined;

    if (kIsWeb) {
      final origin = Uri.base.origin;
      // Jika diakses dari domain live (atau bukan localhost/127.0.0.1)
      if (origin.isNotEmpty && !origin.contains('localhost') && !origin.contains('127.0.0.1')) {
        return origin;
      }
      return kReleaseMode ? liveProductionUrl : 'http://localhost:8000';
    }

    if (kReleaseMode) {
      return liveProductionUrl;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator mengakses host via 10.0.2.2 pada mode debug
      return 'http://10.0.2.2:8000';
    }

    return 'http://localhost:8000';
  }

  static String get apiUrl => '$baseUrl/api/v1';
}
