import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:nagah/features/auth/data/model/auth_models.dart';

class AuthSessionLocalDataSource {
  static const _sessionKey = 'auth_session';

  Future<void> saveSession(AuthUserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(user.toJson()));
  }

  Future<AuthUserModel?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final rawSession = prefs.getString(_sessionKey);
    if (rawSession == null || rawSession.isEmpty) {
      return null;
    }

    return AuthUserModel.fromJson(
      Map<String, dynamic>.from(jsonDecode(rawSession)),
    );
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
