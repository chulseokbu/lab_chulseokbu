/// 회원 가입 요청 DTO
class MemberSignupRequestDto {
  final int memberId;
  final String nickname;
  final String password;
  final String email;
  final String phone;

  MemberSignupRequestDto({
    required this.memberId,
    required this.nickname,
    required this.password,
    required this.email,
    required this.phone,
  });

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'nickname': nickname,
        'password': password,
        'email': email,
        'phone': phone,
      };
}

/// 회원 가입 응답 DTO
class MemberResponseDto {
  final int? id;
  final int? memberId;
  final String? nickname;
  final String? email;

  MemberResponseDto({
    this.id,
    this.memberId,
    this.nickname,
    this.email,
  });

  factory MemberResponseDto.fromJson(Map<String, dynamic> json) =>
      MemberResponseDto(
        id: json['id'] as int?,
        memberId: json['memberId'] as int?,
        nickname: json['nickname'] as String?,
        email: json['email'] as String?,
      );
}

/// 로그인 요청 DTO
class LoginRequestDto {
  final String email;
  final String password;

  LoginRequestDto({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

/// 로그인 응답 DTO
class LoginResponseDto {
  final String? accessToken;
  final int? memberId;
  final String? username;
  final String? phone;
  final String? email;
  final String? studentId;

  LoginResponseDto({
    this.accessToken,
    this.memberId,
    this.username,
    this.phone,
    this.email,
    this.studentId,
  });

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  static Map<String, dynamic>? _map(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  /// 백엔드마다 `accessToken` / `access_token` / `token` / `data` 래핑 등이 달라서 통일해 파싱
  static String? _readAccessToken(Map<String, dynamic> json) {
    const rootKeys = [
      'accessToken',
      'access_token',
      'token',
      'jwt',
      'access',
    ];
    for (final key in rootKeys) {
      final s = _str(json[key])?.trim();
      if (s != null && s.isNotEmpty) return s;
    }
    for (final nest in ['data', 'result', 'body']) {
      final inner = _map(json[nest]);
      if (inner == null) continue;
      for (final key in rootKeys) {
        final s = _str(inner[key])?.trim();
        if (s != null && s.isNotEmpty) return s;
      }
    }
    return null;
  }

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    final nestedUser = _map(json['user']) ?? _map(json['member']);
    return LoginResponseDto(
      accessToken: _readAccessToken(json),
      memberId: _parseInt(json['memberId']) ??
          _parseInt(json['id']) ??
          (nestedUser != null
              ? (_parseInt(nestedUser['memberId']) ?? _parseInt(nestedUser['id']))
              : null),
      username: _str(json['username']) ??
          _str(json['nickname']) ??
          (nestedUser != null
              ? (_str(nestedUser['username']) ?? _str(nestedUser['nickname']))
              : null),
      phone: _str(json['phone']) ??
          (nestedUser != null ? _str(nestedUser['phone']) : null),
      email: _str(json['email']) ??
          (nestedUser != null ? _str(nestedUser['email']) : null),
      studentId: _str(json['studentId']) ??
          (nestedUser != null ? _str(nestedUser['studentId']) : null),
    );
  }
}
