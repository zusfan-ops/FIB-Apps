import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'api_client.dart';

class Session {
  Session._();
  static final Session instance = Session._();

  static const _kToken = 'auth_token';
  static const _kUser = 'auth_user';

  User? user;

  bool get isLoggedIn => ApiClient.instance.token != null;

  Future<void> save(String token, User user) async {
    ApiClient.instance.setToken(token);
    this.user = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString(_kUser, jsonEncode(user.toJson()));
  }

  Future<void> updateUser(User user) async {
    this.user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUser, jsonEncode(user.toJson()));
  }

  Future<bool> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);
    final userJson = prefs.getString(_kUser);

    if (token == null) return false;

    ApiClient.instance.setToken(token);
    if (userJson != null) {
      try {
        user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {
        user = null;
      }
    }
    return true;
  }

  Future<void> clear() async {
    ApiClient.instance.setToken(null);
    user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUser);
  }
}
