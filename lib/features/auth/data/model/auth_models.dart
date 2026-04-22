import 'package:nagah/features/auth/domain/model/auth_models.dart';

class AuthUserModel {
  const AuthUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.token,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? token;

  AuthUser toEntity() => AuthUser(
    id: id,
    name: name,
    email: email,
    role: role,
    token: token,
  );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'token': token,
    };
  }

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() == 'admin'
          ? UserRole.admin
          : UserRole.user,
      token: json['token']?.toString(),
    );
  }
}

class OtpSessionModel {
  const OtpSessionModel({
    required this.sessionId,
    required this.email,
    required this.purpose,
  });

  final String sessionId;
  final String email;
  final OtpPurpose purpose;

  OtpSession toEntity() {
    return OtpSession(
      sessionId: sessionId,
      email: email,
      purpose: purpose,
    );
  }
}

class PendingRegistrationModel {
  const PendingRegistrationModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });

  final String name;
  final String email;
  final String phone;
  final String password;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    };
  }

  factory PendingRegistrationModel.fromJson(Map<String, dynamic> json) {
    return PendingRegistrationModel(
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
    );
  }
}
