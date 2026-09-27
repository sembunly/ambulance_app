// ── Signup request model ──────────────────────────────────────────────────
class SignupRequest {
  const SignupRequest({
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.password,
    this.gender = '',
    this.dateOfBirth = '',
  });

  final String fullName;
  final String phoneNumber;
  final String email;
  final String password;
  final String gender;
  final String dateOfBirth;

  // ── First name ──────────────────────────────────────────────────────────
  String get firstName {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '';
    }

    return parts.first;
  }

  // ── Last name ───────────────────────────────────────────────────────────
  String get lastName {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length <= 1) {
      return parts.isEmpty ? '' : parts.first;
    }

    return parts.sublist(1).join(' ');
  }

  // ── Username ────────────────────────────────────────────────────────────
  String get username {
    final cleanEmail = email.trim();

    if (cleanEmail.contains('@')) {
      final value = cleanEmail.split('@').first;

      if (value.isNotEmpty) {
        return value;
      }
    }

    return phoneNumber.trim();
  }

  // ── JSON serialization ──────────────────────────────────────────────────
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'username': username,
      'email': email.trim(),
      'phoneNumber': phoneNumber.trim(),
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'avatar': '',
      'gender': gender.trim(),
      'dateOfBirth': dateOfBirth.trim(),
    };
  }
}
