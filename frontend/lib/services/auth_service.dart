import 'dart:convert';

import 'package:frontend/HomeTab/Views/Profile_Service.dart';
import 'package:frontend/api/api_config.dart';
import 'package:frontend/models/auth_models.dart';
import 'package:frontend/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 인증 서비스 - 로그인, 회원가입, 토큰 관리
class AuthService {
  AuthService._();

  static const String _keyAccessToken = 'access_token';
  static const String _keyMemberId = 'member_id';
  static const String _keyEmail = 'email';
  static const String _keyUsername = 'username';

  static final AuthService _instance = AuthService._();
  static AuthService get instance => _instance;

  final ApiClient _client = ApiClient.instance;

  /// 로그인
  /// - 성공 시 토큰 저장 후 LoginResponseDto 반환
  /// - 실패 시 ApiException throw
  Future<LoginResponseDto> login(String email, String password) async {
    final res = await _client.post(ApiConfig.login, body: {
      'email': email,
      'password': password,
    });

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final dto = LoginResponseDto.fromJson(json);
      if (dto.accessToken != null) {
        await _saveAuth(dto);
        _client.setToken(dto.accessToken);
      }
      return dto;
    }

    if (res.statusCode == 401) {
      throw ApiException('이메일 또는 비밀번호가 일치하지 않습니다.');
    }
    if (res.statusCode == 400) {
      throw ApiException(_parseValidationError(res.body));
    }
    throw ApiException('로그인에 실패했습니다. (${res.statusCode})');
  }

  /// 이메일/애플 등 로그인 성공 후 로컬·ApiClient 반영 (LoginScreen 중복 로직 대체용)
  Future<void> applyLoginSuccess(LoginResponseDto dto) async {
    final token = dto.accessToken?.trim();
    if (token != null && token.isNotEmpty) {
      await _saveAuth(dto);
      _client.setToken(token);
    }
    final profileService = ProfileService();
    final dynamic rawMemberId = dto.memberId;
    final int? memberIdInt =
        (rawMemberId is int) ? rawMemberId : int.tryParse(rawMemberId?.toString() ?? '');
    await profileService.saveProfile(
      name: dto.username ?? '',
      studentId: (dto.studentId != null && dto.studentId!.isNotEmpty)
          ? dto.studentId!
          : (dto.memberId?.toString() ?? ''),
      phone: dto.phone,
      email: dto.email,
      accessToken: dto.accessToken,
      memberId: memberIdInt,
    );
    await profileService.generateAndSaveUniqueId();
  }

  /// 회원 가입
  Future<MemberResponseDto> signup(MemberSignupRequestDto dto) async {
    final res = await _client.post(ApiConfig.signup, body: dto.toJson());

    if (res.statusCode == 201) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return MemberResponseDto.fromJson(json);
    }

    if (res.statusCode == 409) {
      throw ApiException('이미 사용 중인 이메일입니다.');
    }
    if (res.statusCode == 400) {
      throw ApiException(_parseValidationError(res.body));
    }
    throw ApiException('회원가입에 실패했습니다. (${res.statusCode})');
  }

  /// 로그아웃 - 토큰 삭제
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove('accessToken');
    await prefs.remove(_keyMemberId);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyUsername);
    _client.setToken(null);
  }

  /// 앱 시작 시 저장된 토큰 복원
  /// [LoginScreen]은 ProfileService 키 `accessToken`에 저장하므로 둘 다 조회한다.
  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString(_keyAccessToken);
    token ??= prefs.getString('accessToken');
    final trimmed = token?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      _client.setToken(trimmed);
      if (prefs.getString(_keyAccessToken) == null) {
        await prefs.setString(_keyAccessToken, trimmed);
      }
      return true;
    }
    return false;
  }

  /// 로그인 여부
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken) != null;
  }

  Future<void> _saveAuth(LoginResponseDto dto) async {
    final prefs = await SharedPreferences.getInstance();
    if (dto.accessToken != null) {
      await prefs.setString(_keyAccessToken, dto.accessToken!);
    }
    if (dto.memberId != null) {
      await prefs.setInt(_keyMemberId, dto.memberId!);
    }
    if (dto.email != null) {
      await prefs.setString(_keyEmail, dto.email!);
    }
    if (dto.username != null) {
      await prefs.setString(_keyUsername, dto.username!);
    }
  }

  String _parseValidationError(String body) {
    try {
      final list = jsonDecode(body) as List;
      if (list.isNotEmpty && list.first is Map) {
        final first = list.first as Map<String, dynamic>;
        return first['defaultMessage'] as String? ?? '입력값을 확인해주세요.';
      }
    } catch (_) {}
    return body.isNotEmpty ? body : '입력값을 확인해주세요.';
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
