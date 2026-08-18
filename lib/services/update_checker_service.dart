import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../widgets/update_dialog.dart';

/// Model representasi data Release dari GitHub API
class GitHubRelease {
  final String tagName;
  final String name;
  final String body;
  final DateTime publishedAt;
  final String htmlUrl;
  final String? apkDownloadUrl;
  final String? apkFileName;
  final int? apkSizeBytes;

  GitHubRelease({
    required this.tagName,
    required this.name,
    required this.body,
    required this.publishedAt,
    required this.htmlUrl,
    this.apkDownloadUrl,
    this.apkFileName,
    this.apkSizeBytes,
  });

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    final assets = (json['assets'] as List<dynamic>?) ?? [];
    String? apkUrl;
    String? apkName;
    int? apkSize;

    // Prioritaskan arsitektur arm64-v8a, lalu universal apk, atau apk apa pun yang ditemukan
    for (final asset in assets) {
      if (asset is Map<String, dynamic>) {
        final name = (asset['name'] ?? '').toString().toLowerCase();
        final url = (asset['browser_download_url'] ?? '').toString();
        final size = asset['size'] as int?;

        if (name.endsWith('.apk')) {
          if (name.contains('arm64-v8a') || apkUrl == null) {
            apkUrl = url;
            apkName = asset['name'] as String?;
            apkSize = size;
          }
        }
      }
    }

    return GitHubRelease(
      tagName: (json['tag_name'] ?? 'v1.0.0') as String,
      name: (json['name'] ?? json['tag_name'] ?? 'Pembaruan Aplikasi') as String,
      body: (json['body'] ?? '') as String,
      publishedAt: DateTime.tryParse(json['published_at'] ?? '') ?? DateTime.now(),
      htmlUrl: (json['html_url'] ?? 'https://github.com/zusfan-ops/FIB-Backend/releases') as String,
      apkDownloadUrl: apkUrl,
      apkFileName: apkName,
      apkSizeBytes: apkSize,
    );
  }

  String get versionClean {
    return tagName.startsWith('v') || tagName.startsWith('V')
        ? tagName.substring(1)
        : tagName;
  }
}

/// Service untuk memeriksa rilis APK baru di GitHub Releases secara otomatis
class UpdateCheckerService {
  UpdateCheckerService._();
  static final UpdateCheckerService instance = UpdateCheckerService._();

  /// Versi aplikasi saat ini
  static const String currentVersion = '1.2.0';

  /// Daftar repositori GitHub yang diperiksa
  static const List<String> _repos = [
    'zusfan-ops/FIB-Backend',
    'zusfan-ops/FIB-Apps',
  ];

  DateTime? _lastCheckedAt;
  GitHubRelease? _latestRelease;
  bool _isChecking = false;

  /// Memeriksa apakah ada versi baru di GitHub Releases
  Future<GitHubRelease?> checkLatestRelease({bool force = false}) async {
    // Jika baru saja diperiksa dalam 5 menit terakhir dan tidak force, gunakan cache
    if (!force && _lastCheckedAt != null && _latestRelease != null) {
      if (DateTime.now().difference(_lastCheckedAt!).inMinutes < 5) {
        return _latestRelease;
      }
    }

    if (_isChecking) return _latestRelease;
    _isChecking = true;

    try {
      for (final repo in _repos) {
        try {
          final uri = Uri.parse('https://api.github.com/repos/$repo/releases/latest');
          final response = await http.get(uri, headers: {
            'Accept': 'application/vnd.github.v3+json',
          }).timeout(const Duration(seconds: 8));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final release = GitHubRelease.fromJson(data);

            if (_isNewerVersion(release.versionClean, currentVersion)) {
              _latestRelease = release;
              _lastCheckedAt = DateTime.now();
              return release;
            }
          }
        } catch (e) {
          debugPrint('UpdateChecker error on repo $repo: $e');
        }
      }
    } finally {
      _isChecking = false;
    }

    _lastCheckedAt = DateTime.now();
    return null;
  }

  /// Membandingkan dua string versi semantic (misal: "1.1.0" > "1.0.0")
  bool _isNewerVersion(String newVer, String currentVer) {
    try {
      final newParts = newVer.split('.').map((e) => int.tryParse(e.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0).toList();
      final curParts = currentVer.split('.').map((e) => int.tryParse(e.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0).toList();

      while (newParts.length < 3) {
        newParts.add(0);
      }
      while (curParts.length < 3) {
        curParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (newParts[i] > curParts[i]) return true;
        if (newParts[i] < curParts[i]) return false;
      }
    } catch (_) {}
    return false;
  }

  /// Memeriksa pembaruan dan menampilkan dialog jika tersedia
  Future<void> checkAndShowUpdateDialog(
    BuildContext context, {
    bool isManualCheck = false,
  }) async {
    if (kIsWeb && !isManualCheck) {
      // Pada Web browser, update APK tidak perlu diprompt otomatis saat startup
      return;
    }

    if (isManualCheck) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Memeriksa update di GitHub Releases...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }

    final release = await checkLatestRelease(force: isManualCheck);

    if (!context.mounted) return;

    if (release != null) {
      // Tampilkan dialog pembaruan
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => UpdateDialog(
          release: release,
          currentVersion: currentVersion,
        ),
      );
    } else if (isManualCheck) {
      // Beritahu pengguna bahwa aplikasi sudah versi terbaru
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 28),
              SizedBox(width: 10),
              Text('Versi Terbaru'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aplikasi FIB UNDIP Anda sudah menggunakan versi paling mutakhir (v$currentVersion).',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tidak ada update APK baru di GitHub saat ini.',
                style: TextStyle(color: Colors.grey, fontSize: 12.5),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    }
  }

  /// Membuka link download file APK atau rilis GitHub di browser
  Future<void> openDownloadUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
