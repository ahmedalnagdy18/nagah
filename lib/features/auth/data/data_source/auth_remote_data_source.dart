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

    final user = users.first;
    final isVerified = user['is_verified'] == true ||
        user['is_verified']?.toString().toLowerCase() == 'true';
    if (!isVerified) {
      throw Exception('Email not verified. Please verify your OTP first.');
    }

    return _mapUser(user);
  }

  Future<OtpSessionModel> register(RegisterParams params) async {
    final normalizedName = params.name.trim();
    final normalizedEmail = params.email.trim().toLowerCase();
    final normalizedPhone = params.phone.trim();

    if (normalizedName.length < 3) {
      throw Exception('Name must be at least 3 characters.');
    }
    _validateEmail(normalizedEmail);
    if (normalizedPhone.length < 11) {
      throw Exception('Phone number looks too short.');
    }
    _validatePassword(params.password);

    final existingUsers = await _client.getList(
      'users',
      query: {
        'select': 'id,email,phone',
        'email': 'eq.$normalizedEmail',
      },
    );

    if (existingUsers.isNotEmpty) {
      throw Exception(
        'This email is already registered. Please log in instead.',
      );
    }

    final existingPhoneUsers = await _client.getList(
      'users',
      query: {
        'select': 'id,phone',
        'phone': 'eq.$normalizedPhone',
      },
    );

    if (existingPhoneUsers.isNotEmpty) {
      throw Exception(
        'This phone number is already registered. Please use another one.',
      );
    }

    final code = '123456';
    await _saveOtpSession(
      sessionId: normalizedEmail,
      email: normalizedEmail,
      purpose: 'register',
      code: code,
    );

    return OtpSessionModel(
      sessionId: normalizedEmail,
      email: normalizedEmail,
      purpose: OtpPurpose.register,
    );
  }

  Future<OtpSessionModel> requestPasswordReset(
    ForgotPasswordParams params,
  ) async {
    _validateEmail(params.email);

    final normalizedEmail = params.email.trim().toLowerCase();
    final users = await _client.getList(
      'users',
      query: {
        'select': 'id,email,phone',
        'email': 'eq.$normalizedEmail',
      },
    );

    if (users.isEmpty) {
      throw Exception('No account found with this email.');
    }

    await _saveOtpSession(
      sessionId: normalizedEmail,
      email: normalizedEmail,
      purpose: 'reset_password',
      code: '123456',
    );

    return OtpSessionModel(
      sessionId: normalizedEmail,
      email: normalizedEmail,
      purpose: OtpPurpose.resetPassword,
    );
  }

  Future<OtpSessionModel> verifyOtp(VerifyOtpParams params) async {
    final normalizedEmail = params.sessionId.trim().toLowerCase();
    final otpRows = await _client.getList(
      'otp_sessions',
      query: {
        'select': '*',
        'id': 'eq.$normalizedEmail',
        'email': 'eq.$normalizedEmail',
        'code': 'eq.${params.code.trim()}',
        'is_verified': 'eq.false',
        'limit': '1',
      },
    );

    if (otpRows.isEmpty) {
      throw Exception('Invalid OTP code.');
    }

    final expiresAt = _parseOtpExpiry(otpRows.first['expires_at']?.toString());
    if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
      throw Exception('OTP code has expired. Please request a new one.');
    }

    await _client.update(
      'otp_sessions',
      query: {'id': 'eq.$normalizedEmail'},
      body: {'is_verified': true},
    );

    final purpose = otpRows.first['purpose']?.toString() == 'register'
        ? OtpPurpose.register
        : OtpPurpose.resetPassword;

    return OtpSessionModel(
      sessionId: normalizedEmail,
      email: normalizedEmail,
      purpose: purpose,
    );
  }

  Future<void> resendOtp(String email) async {
    _validateEmail(email);

    final normalizedEmail = email.trim().toLowerCase();
    final existingSessions = await _client.getList(
      'otp_sessions',
      query: {
        'select': 'id,email,purpose',
        'id': 'eq.$normalizedEmail',
        'limit': '1',
      },
    );

    if (existingSessions.isNotEmpty) {
      await _saveOtpSession(
        sessionId: normalizedEmail,
        email: normalizedEmail,
        purpose: existingSessions.first['purpose']?.toString() ?? 'register',
        code: '123456',
      );
      return;
    }

    final users = await _client.getList(
      'users',
      query: {
        'select': 'id,email,phone,is_verified',
        'email': 'eq.$normalizedEmail',
      },
    );

    if (users.isEmpty) {
      throw Exception('User not found.');
    }

    final user = users.first;
    final isVerified = user['is_verified'] == true ||
        user['is_verified']?.toString().toLowerCase() == 'true';
    if (isVerified) {
      throw Exception('User already verified.');
    }

    await _saveOtpSession(
      sessionId: normalizedEmail,
      email: normalizedEmail,
      purpose: 'register',
      code: '123456',
    );
  }

  Future<AuthUserModel> resetPassword(ResetPasswordParams params) async {
    if (params.password != params.confirmPassword) {
      throw Exception('Passwords do not match.');
    }
    _validatePassword(params.password);

    final normalizedEmail = params.sessionId.trim().toLowerCase();
    final updatedUsers = await _client.update(
      'users',
      query: {'email': 'eq.$normalizedEmail'},
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

  Future<AuthUserModel> getCurrentUser(String userId) async {
    final users = await _client.getList(
      'users',
      query: {
        'select': '*',
        'id': 'eq.$userId',
        'limit': '1',
      },
    );

    if (users.isEmpty) {
      throw Exception('User session not found.');
    }

    return _mapUser(users.first);
  }

  AuthUserModel _mapUser(Map<String, dynamic> json) {
    final isAdmin = json['is_admin'] == true ||
        json['is_admin']?.toString().toLowerCase() == 'true';

    return AuthUserModel(
      id: json['id']?.toString() ?? '',
      name:
          json['full_name']?.toString() ??
          json['name']?.toString() ??
          'Nagah User',
      email: json['email']?.toString() ?? '',
      role: isAdmin ? UserRole.admin : UserRole.user,
      token: json['id']?.toString(),
    );
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

  String _buildOtpExpiry() {
    return DateTime.now().add(const Duration(minutes: 10)).toIso8601String();
  }

  DateTime? _parseOtpExpiry(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(rawValue.trim());
    return parsed?.toLocal();
  }

  Future<void> completeRegistration({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPhone = phone.trim();

    if (normalizedName.length < 3) {
      throw Exception('Name must be at least 3 characters.');
    }
    _validateEmail(normalizedEmail);
    if (normalizedPhone.length < 11) {
      throw Exception('Phone number looks too short.');
    }
    _validatePassword(password);

    final existingUsers = await _client.getList(
      'users',
      query: {
        'select': 'id,email',
        'email': 'eq.$normalizedEmail',
        'limit': '1',
      },
    );

    if (existingUsers.isNotEmpty) {
      throw Exception('This email is already registered. Please log in instead.');
    }

    final existingPhoneUsers = await _client.getList(
      'users',
      query: {
        'select': 'id,phone',
        'phone': 'eq.$normalizedPhone',
        'limit': '1',
      },
    );

    if (existingPhoneUsers.isNotEmpty) {
      throw Exception(
        'This phone number is already registered. Please use another one.',
      );
    }

    await _client.insert(
      'users',
      body: {
        'email': normalizedEmail,
        'phone': normalizedPhone,
        'password_hash': password.trim(),
        'full_name': normalizedName,
        'is_verified': true,
        'is_admin': false,
      },
    );
  }

  Future<void> _saveOtpSession({
    required String sessionId,
    required String email,
    required String purpose,
    required String code,
  }) async {
    final existingSessions = await _client.getList(
      'otp_sessions',
      query: {
        'select': 'id',
        'id': 'eq.$sessionId',
        'limit': '1',
      },
    );

    final body = {
      'id': sessionId,
      'email': email,
      'purpose': purpose,
      'code': code,
      'is_verified': false,
      'expires_at': _buildOtpExpiry(),
    };

    if (existingSessions.isEmpty) {
      await _client.insert('otp_sessions', body: body);
      return;
    }

    await _client.update(
      'otp_sessions',
      query: {'id': 'eq.$sessionId'},
      body: body,
    );
  }
}
