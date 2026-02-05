import 'dart:convert';

import 'package:frontend/api/api_config.dart';
import 'package:frontend/models/attendance_models.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/auth_service.dart';

/// 출석 서비스 - 체크인, 체크아웃
class AttendanceService {
  AttendanceService._();

  static final AttendanceService _instance = AttendanceService._();
  static AttendanceService get instance => _instance;

  final ApiClient _client = ApiClient.instance;

  /// 체크인 (입실)
  /// - 성공 시 checkInId 반환
  Future<int> checkIn() async {
    final res = await _client.post(ApiConfig.checkIn);

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final apiRes = ApiResponse.fromJson(
        json,
        (d) => d is Map ? CheckInDto.fromJson(d as Map<String, dynamic>) : null,
      );
      if (apiRes.success && apiRes.data != null) {
        return apiRes.data!.checkInId;
      }
      throw ApiException(apiRes.message ?? '체크인에 실패했습니다.');
    }

    if (res.statusCode == 400) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final apiRes = ApiResponse.fromJson(json, (_) => null);
      throw ApiException(apiRes.message ?? '이미 체크인 되어 있습니다.');
    }
    throw ApiException('체크인에 실패했습니다. (${res.statusCode})');
  }

  /// 체크아웃 (퇴실)
  Future<void> checkOut(int inoutId) async {
    final res = await _client.post(ApiConfig.checkOut(inoutId));

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final apiRes = NoDataApiResponse.fromJson(json);
      if (!apiRes.success) {
        throw ApiException(apiRes.message ?? '체크아웃에 실패했습니다.');
      }
      return;
    }

    if (res.statusCode == 400 || res.statusCode == 404) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final apiRes = NoDataApiResponse.fromJson(json);
      throw ApiException(apiRes.message ?? '체크아웃에 실패했습니다.');
    }
    throw ApiException('체크아웃에 실패했습니다. (${res.statusCode})');
  }
}
