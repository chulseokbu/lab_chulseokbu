import 'dart:convert';

import 'package:frontend/api/api_config.dart';
import 'package:frontend/models/auth_models.dart';
import 'package:frontend/services/apple_auth_login_status.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/auth_service.dart';

/// 애플 로그인 API 결과
sealed class AppleAuthResult {}

class AppleAuthLoggedIn extends AppleAuthResult {
  AppleAuthLoggedIn(this.dto);
  final LoginResponseDto dto;
}

class AppleAuthNeedsProfile extends AppleAuthResult {
  AppleAuthNeedsProfile();
}

/// 애플 인증 — Firebase 없이 서버가 identityToken 검증
class AppleAuthService {
  AppleAuthService._();
  static final AppleAuthService instance = AppleAuthService._();

  final ApiClient _client = ApiClient.instance;

  /// 기존 연동 회원이면 [AppleAuthLoggedIn], 최초면 [AppleAuthNeedsProfile]
  Future<AppleAuthResult> loginWithAppleToken({
    required String identityToken,
    String? authorizationCode,
    String? userIdentifier,
  }) async {
    final res = await _client.postWithoutAuth(
      ApiConfig.appleAuth,
      body: {
        'identityToken': identityToken,
        if (authorizationCode != null && authorizationCode.isNotEmpty)
          'authorizationCode': authorizationCode,
        if (userIdentifier != null && userIdentifier.isNotEmpty)
          'userIdentifier': userIdentifier,
      },
    );

    final kind = AppleAuthLoginStatus.classify(res.statusCode);
    if (kind == AppleAuthLoginKind.loggedIn) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return AppleAuthLoggedIn(LoginResponseDto.fromJson(json));
    }
    if (kind == AppleAuthLoginKind.needsOnboarding) {
      return AppleAuthNeedsProfile();
    }

    if (res.statusCode == 401) {
      throw ApiException('애플 로그인에 실패했습니다. 다시 시도해주세요.');
    }
    if (res.statusCode == 404) {
      throw ApiException(
        _messageFromBody(res.body) ?? '애플 로그인에 실패했습니다. 서버 응답을 확인해주세요.',
      );
    }
    throw ApiException(
        _messageFromBody(res.body) ?? '애플 로그인에 실패했습니다. (${res.statusCode})');
  }

  /// 온보딩 제출 후 로그인 응답
  Future<LoginResponseDto> completeAppleProfile({
    required String identityToken,
    String? authorizationCode,
    String? userIdentifier,
    required int memberId,
    required String nickname,
    required String phone,
    required String email,
    required String gender,
  }) async {
    final res = await _client.postWithoutAuth(
      ApiConfig.appleCompleteProfile,
      body: {
        'identityToken': identityToken,
        if (authorizationCode != null && authorizationCode.isNotEmpty)
          'authorizationCode': authorizationCode,
        if (userIdentifier != null && userIdentifier.isNotEmpty)
          'userIdentifier': userIdentifier,
        'memberId': memberId,
        'nickname': nickname,
        'phone': phone,
        'email': email,
        'gender': gender,
      },
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return LoginResponseDto.fromJson(json);
    }

    if (res.statusCode == 409) {
      throw ApiException('이미 사용 중인 이메일(또는 학번)입니다.');
    }
    if (res.statusCode == 400) {
      throw ApiException(_parseValidation(res.body));
    }
    throw ApiException(
        _messageFromBody(res.body) ?? '가입 완료에 실패했습니다. (${res.statusCode})');
  }

  String? _messageFromBody(String body) {
    try {
      final m = jsonDecode(body) as Map<String, dynamic>;
      return m['message'] as String?;
    } catch (_) {
      return null;
    }
  }

  String _parseValidation(String body) {
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
