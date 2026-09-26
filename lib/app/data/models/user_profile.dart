import 'package:equatable/equatable.dart';

/// Profile data returned by the authenticated user profile endpoint.
class UserProfile extends Equatable {
  const UserProfile({
    required this.userId,
    this.avatar = '',
    this.firstName = '',
    this.lastName = '',
    this.username = '',
    this.email = '',
    this.phone = '',
    this.gender = '',
    this.dateOfBirth,
    this.roleNames = const <String>[],
    this.roleCodes = const <String>[],
    this.accountStatus = '',
    this.lastLoginAt,
    this.createdAt,
  });

  final String userId;
  final String avatar;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String phone;
  final String gender;
  final DateTime? dateOfBirth;
  final List<String> roleNames;
  final List<String> roleCodes;
  final String accountStatus;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;

  String get fullName {
    final joined = [
      firstName,
      lastName,
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();
    if (joined.isNotEmpty) return joined;
    if (username.trim().isNotEmpty) return username.trim();
    return 'Unknown';
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawBody = json['body'];
    final envelope = rawBody is Map<String, dynamic>
        ? rawBody
        : rawBody is Map
        ? rawBody.map((key, value) => MapEntry(key.toString(), value))
        : json;
    final rawData = envelope['data'];
    final rawProfile = rawData is List && rawData.isNotEmpty
        ? rawData.first
        : rawData is Map
        ? rawData
        : envelope;
    final body = rawProfile is Map<String, dynamic>
        ? rawProfile
        : rawProfile is Map
        ? rawProfile.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};

    return UserProfile(
      userId: _readString(body, ['userId', 'id', 'user_id']),
      avatar: _readString(body, [
        'avatar',
        'photoUrl',
        'photo_url',
        'profileImage',
        'profile_image',
      ]),
      firstName: _readString(body, ['firstName', 'first_name', 'firstname']),
      lastName: _readString(body, ['lastName', 'last_name', 'lastname']),
      username: _readString(body, ['username', 'userName']),
      email: _readString(body, ['email', 'emailAddress', 'email_address']),
      phone: _readString(body, [
        'phone',
        'phoneNumber',
        'phone_number',
        'mobile',
      ]),
      gender: _readString(body, ['gender', 'sex']),
      dateOfBirth: _parseDate(
        body['dateOfBirth'] ?? body['date_of_birth'] ?? body['dob'],
      ),
      roleNames: _parseStringList(
        body['roleNames'] ?? body['role_names'] ?? body['roles'],
      ),
      roleCodes: _parseStringList(body['roleCodes'] ?? body['role_codes']),
      accountStatus: _readString(body, [
        'accountStatus',
        'status',
        'userStatus',
      ]),
      lastLoginAt: _parseDate(body['lastLoginAt'] ?? body['last_login_at']),
      createdAt: _parseDate(body['createdAt'] ?? body['created_at']),
    );
  }

  static String _readString(Map<String, dynamic> body, List<String> keys) {
    for (final key in keys) {
      final value = body[key];
      if (value == null) continue;
      final stringValue = value.toString().trim();
      if (stringValue.isNotEmpty) return stringValue;
    }
    return '';
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static List<String> _parseStringList(Object? value) {
    if (value is List) {
      return List<String>.unmodifiable(
        value
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty),
      );
    }

    if (value is String) {
      return List<String>.unmodifiable(
        value
            .split(RegExp(r'[;,]'))
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty),
      );
    }

    return const <String>[];
  }

  @override
  List<Object?> get props => [
    userId,
    avatar,
    firstName,
    lastName,
    username,
    email,
    phone,
    gender,
    dateOfBirth,
    roleNames,
    roleCodes,
    accountStatus,
    lastLoginAt,
    createdAt,
  ];
}
