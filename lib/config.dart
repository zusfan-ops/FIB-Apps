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
      final uri = Uri.base;
      final host = uri.host.toLowerCase();
      final origin = uri.origin;

      // 1. Jika diakses dari domain live produksi resmi
      if (host == 'fib.ordr.my.id' || host.endsWith('.ordr.my.id')) {
        return origin;
      }

      // 2. Jika diakses dari static hosting pihak ketiga (GitHub Pages, Vercel, Firebase, Netlify, Pages)
      if (host.endsWith('github.io') ||
          host.endsWith('vercel.app') ||
          host.endsWith('web.app') ||
          host.endsWith('firebaseapp.com') ||
          host.endsWith('netlify.app') ||
          host.endsWith('pages.dev')) {
        return liveProductionUrl;
      }

      // 3. Jika diakses dari local network IP / localhost (192.168.x.x, 10.x.x.x, 127.0.0.1, localhost)
      final isLocalIpOrHost = host == 'localhost' ||
          host == '127.0.0.1' ||
          host.startsWith('192.168.') ||
          host.startsWith('10.') ||
          host.startsWith('172.') ||
          host.endsWith('.local') ||
          host.endsWith('.test');

      if (isLocalIpOrHost) {
        // Jika web dibuka langsung dari port backend Laravel (misal :8000 atau port 80 / tanpa custom dev port)
        if (uri.port == 8000 || uri.port == 80 || uri.port == 443 || uri.hasPort == false) {
          return origin;
        }
        // Jika web dibuka via dev server Flutter Web (misal port 8080, 3000, 5000, dll)
        // Maka backend Laravel berada pada IP host yang sama pada port 8000
        return '${uri.scheme}://${uri.host}:8000';
      }

      // 4. Default web fallback
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
