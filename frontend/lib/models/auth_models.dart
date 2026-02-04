/// 회원 가입 요청 DTO
class MemberSignupRequestDto {
  final int memberId;
  final String nickname;
  final String password;
  final String email;
  final String phone;
  final String gender; // "MALE" | "FEMALE"

  MemberSignupRequestDto({
    required this.memberId,
    required this.nickname,
    required this.password,
    required this.email,
    required this.phone,
    required this.gender,
  });

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'nickname': nickname,
        'password': password,
        'email': email,
        'phone': phone,
        'gender': gender,
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

  LoginResponseDto({
    this.accessToken,
    this.memberId,
    this.username,
    this.phone,
    this.email,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) =>
      LoginResponseDto(
        accessToken: json['accessToken'] as String?,
        memberId: json['memberId'] as int?,
        username: json['username'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
      );
}
