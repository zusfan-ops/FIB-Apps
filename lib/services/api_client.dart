import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic>? errors;

  ApiException(this.message, {this.statusCode = 0, this.errors});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String? _token;

  void setToken(String? token) => _token = token;

  String? get token => _token;

  Uri _uri(String path) => Uri.parse('${AppConfig.apiUrl}$path');

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 14; Mobile; SakuraKotoba/1.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> get(String path) async {
    return _send('GET', path);
  }

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    return _send('POST', path, body);
  }

  Future<dynamic> put(String path, [Map<String, dynamic>? body]) async {
    return _send('PUT', path, body);
  }

  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) async {
    return _send('PATCH', path, body);
  }

  Future<dynamic> delete(String path) async {
    return _send('DELETE', path);
  }

  Future<dynamic> postMultipart(
    String path, {
    required Map<String, String> fields,
    required String fileField,
    required List<int> fileBytes,
    required String filename,
  }) async {
    final uri = _uri(path);
    final request = http.MultipartRequest('POST', uri);
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.headers['Accept'] = 'application/json';
    request.fields.addAll(fields);
    request.files.add(
      http.MultipartFile.fromBytes(
        fileField,
        fileBytes,
        filename: filename,
      ),
    );

    try {
      final streamedResponse = await request.send();
      final res = await http.Response.fromStream(streamedResponse);
      final decoded = _decode(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return decoded['data'];
      }

      final message = decoded['message'] ?? 'Gagal mengunggah file (${res.statusCode})';
      throw ApiException(message.toString(), statusCode: res.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal terhubung ke server saat mengunggah: $e');
    }
  }

  Future<dynamic> _send(String method, String path, [Map<String, dynamic>? body]) async {
    final uri = _uri(path);
    late http.Response res;

    try {
      switch (method) {
        case 'GET':
          res = await http.get(uri, headers: _headers);
        case 'POST':
          res = await http.post(uri, headers: _headers, body: jsonEncode(body ?? {}));
        case 'PUT':
          res = await http.put(uri, headers: _headers, body: jsonEncode(body ?? {}));
        case 'PATCH':
          res = await http.patch(uri, headers: _headers, body: jsonEncode(body ?? {}));
        case 'DELETE':
          res = await http.delete(uri, headers: _headers);
        default:
          throw ApiException('Method tidak didukung');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      // Log for debugging (terlihat di inspect / console browser PWA)
      // ignore: avoid_print
      print('[ApiClient] Network error on $method $uri: $e');
      throw ApiException('Gagal terhubung ke server ($uri). Periksa koneksi internet Anda.', statusCode: -1);
    }

    final decoded = _decode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded['data'];
    }

    final message = decoded['message'] ?? 'Terjadi kesalahan (${res.statusCode})';
    throw ApiException(message.toString(), statusCode: res.statusCode, errors: decoded['errors'] as Map<String, dynamic>?);
  }

  Map<String, dynamic> _decode(String body) {
    if (body.isEmpty) return {};
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
