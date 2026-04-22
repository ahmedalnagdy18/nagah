import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:nagah/features/auth/data/model/auth_models.dart';

class AuthSessionLocalDataSource {
  static const _sessionKey = 'auth_session';
  static const _pendingRegistrationKey = 'pending_registration';

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

  Future<void> savePendingRegistration({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingRegistration = PendingRegistrationModel(
      name: name.trim(),
      email: email.trim().toLowerCase(),
      phone: phone.trim(),
      password: password,
    );
    await prefs.setString(
      _pendingRegistrationKey,
      jsonEncode(pendingRegistration.toJson()),
    );
  }

  Future<PendingRegistrationModel?> getPendingRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString(_pendingRegistrationKey);
    if (rawData == null || rawData.isEmpty) {
      return null;
    }

    return PendingRegistrationModel.fromJson(
      Map<String, dynamic>.from(jsonDecode(rawData)),
    );
  }

  Future<void> clearPendingRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingRegistrationKey);
  }
}
