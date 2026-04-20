import 'package:nagah/core/network/supabase_rest_client.dart';
import 'package:nagah/features/auth/data/model/auth_models.dart';
import 'package:nagah/features/auth/domain/model/auth_models.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final SupabaseRestClient _client;

  Future<AuthUserModel> login(LoginParams params) async {
    _validateEmail(params.email);
    _validatePassword(params.password);

    final users = await _client.getList(
      'users',
      query: {
        'select': '*',
        'email': 'eq.${params.email.trim().toLowerCase()}',
        'password_hash': 'eq.${params.password.trim()}',
      },
    );

    if (users.isEmpty) {
      throw Exception('Invalid email or password.');
    }

    return _mapUser(users.first);
  }

  Future<OtpSessionModel> register(RegisterParams params) async {
    if (params.name.trim().length < 3) {
      throw Exception('Name must be at least 3 characters.');
    }
    _validateEmail(params.email);
    if (params.phone.trim().length < 11) {
      throw Exception('Phone number looks too short.');
    }
    _validatePassword(params.password);

    final normalizedEmail = params.email.trim().toLowerCase();
    final existingUsers = await _client.getList(
      'users',
      query: {
        'select': 'id,email',
        'email': 'eq.$normalizedEmail',
      },
    );

    if (existingUsers.isNotEmpty) {
      throw Exception(
        'This email is already registered. Please log in instead.',
      );
    }

    await _client.insert(
      'users',
      body: {
        'email': normalizedEmail,
        'phone': params.phone.trim(),
        'password_hash': params.password.trim(),
        'full_name': params.name.trim(),
        'is_verified': false,
        'is_admin': false,
      },
    );

    final code = _mockOtpCode();
    final otpRow = await _client.insert(
      'otp',
      body: {
        'email': normalizedEmail,
        'code': code,
        'purpose': 'register',
      },
    );

    return _mapOtp(otpRow ?? <String, dynamic>{}, fallbackCode: code);
  }

  Future<OtpSessionModel> requestPasswordReset(
    ForgotPasswordParams params,
  ) async {
    _validateEmail(params.email);

    final code = _mockOtpCode();
    final otpRow = await _client.insert(
      'otp',
      body: {
        'email': params.email.trim().toLowerCase(),
        'code': code,
        'purpose': 'reset_password',
      },
    );

    return _mapOtp(otpRow ?? <String, dynamic>{}, fallbackCode: code);
  }

  Future<OtpSessionModel> verifyOtp(VerifyOtpParams params) async {
    final rows = await _client.getList(
      'otp',
      query: {
        'select': '*',
        'id': 'eq.${params.sessionId}',
        'code': 'eq.${params.code.trim()}',
      },
    );

    if (rows.isEmpty) {
      throw Exception('Invalid OTP code.');
    }

    final row = rows.first;
    final purpose = _parseOtpPurpose(row['purpose']?.toString());
    final email = row['email']?.toString() ?? '';

    if (purpose == OtpPurpose.register) {
      await _client.update(
        'users',
        query: {'email': 'eq.$email'},
        body: {'is_verified': true},
      );
    }

    return _mapOtp(row, fallbackCode: params.code.trim());
  }

  Future<AuthUserModel> resetPassword(ResetPasswordParams params) async {
    if (params.password != params.confirmPassword) {
      throw Exception('Passwords do not match.');
    }
    _validatePassword(params.password);

    final rows = await _client.getList(
      'otp',
      query: {
        'select': '*',
        'id': 'eq.${params.sessionId}',
      },
    );

    if (rows.isEmpty) {
      throw Exception('Reset session not found.');
    }

    final otpRow = rows.first;
    final email = otpRow['email']?.toString();

    if (email == null || email.isEmpty) {
      throw Exception('Reset session email is missing.');
    }

    final updatedUsers = await _client.update(
      'users',
      query: {'email': 'eq.$email'},
      body: {
        'password_hash': params.password.trim(),
        'is_verified': true,
      },
    );

    if (updatedUsers.isEmpty) {
      throw Exception('User was not found for password reset.');
    }

    return _mapUser(updatedUsers.first);
  }

  AuthUserModel _mapUser(Map<String, dynamic> json) {
    final isAdmin =
        json['is_admin'] == true ||
        json['is_admin']?.toString().toLowerCase() == 'true';

    return AuthUserModel(
      id: json['id']?.toString() ?? '',
      name:
          json['full_name']?.toString() ??
          json['name']?.toString() ??
          'Nagah User',
      email: json['email']?.toString() ?? '',
      role: isAdmin ? UserRole.admin : UserRole.user,
    );
  }

  OtpSessionModel _mapOtp(
    Map<String, dynamic> json, {
    required String fallbackCode,
  }) {
    return OtpSessionModel(
      sessionId: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      purpose: _parseOtpPurpose(json['purpose']?.toString()),
      hintCode: json['code']?.toString() ?? fallbackCode,
    );
  }

  OtpPurpose _parseOtpPurpose(String? purpose) {
    return purpose == 'register'
        ? OtpPurpose.register
        : OtpPurpose.resetPassword;
  }

  String _mockOtpCode() {
    // Keep a stable code for the current frontend UX and backend tests.
    return '1234';
  }

  void _validateEmail(String email) {
    if (!email.contains('@') || !email.contains('.')) {
      throw Exception('Please enter a valid email address.');
    }
  }

  void _validatePassword(String password) {
    if (password.trim().length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }
  }
}
