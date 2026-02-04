import 'dart:convert';

import 'package:frontend/api/api_config.dart';
import 'package:http/http.dart' as http;

/// API 클라이언트 - 인증 헤더 자동 첨부
class ApiClient {
  ApiClient._();

  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;

  String? _accessToken;

  void setToken(String? token) {
    _accessToken = token;
  }

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

  Future<http.Response> get(String path) async {
    return http.get(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
    );
  }

  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return http.post(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }
}
