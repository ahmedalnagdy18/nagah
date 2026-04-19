import 'package:nagah/features/auth/domain/model/auth_models.dart';

class AuthUserModel {
  const AuthUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;

  AuthUser toEntity() => AuthUser(id: id, name: name, email: email, role: role);
}

class OtpSessionModel {
  const OtpSessionModel({
    required this.sessionId,
    required this.email,
    required this.purpose,
    required this.hintCode,
  });

  final String sessionId;
  final String email;
  final OtpPurpose purpose;
  final String hintCode;

  OtpSession toEntity() {
    return OtpSession(
      sessionId: sessionId,
      email: email,
      purpose: purpose,
      hintCode: hintCode,
    );
  }
}
