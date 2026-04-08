import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:frontend/api/api_config.dart';
import 'package:http/http.dart' as http;

/// API 클라이언트 - 인증 헤더 자동 첨부
class ApiClient {
  ApiClient._();

  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;

  String? _accessToken;

  /// 빈 문자열은 null과 동일하게 취급. (substring 디버그 로그는 짧은 문자열에서 RangeError 나지 않게 처리)
  void setToken(String? token) {
    final t = token?.trim();
    _accessToken = (t == null || t.isEmpty) ? null : t;
    if (kDebugMode) {
      final p = _accessToken;
      final preview = p == null
          ? 'null'
          : (p.length <= 12 ? '(len ${p.length})' : '${p.substring(0, 12)}…');
      debugPrint('ApiClient.setToken -> $preview');
    }
  }

  // 💡 현재 저장된 토큰이 있는지 확인하는 게터 (디버깅용)
  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;

  // 💡 공통 헤더 생성: 토큰이 있으면 Authorization 헤더를 추가함
  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  /// GET 요청
  Future<http.Response> get(String path) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    return http.get(
      url,
      headers: _headers,
    );
  }

  /// POST 요청
  Future<http.Response> post(
      String path, {
        Map<String, dynamic>? body,
      }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    return http.post(
      url,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  // 💡 로그아웃 시 토큰을 비워주는 메서드 (필요 시 사용)
  void clearToken() {
    _accessToken = null;
  }
}