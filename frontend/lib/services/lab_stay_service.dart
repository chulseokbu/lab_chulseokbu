import 'dart:convert';

import 'package:frontend/api/api_config.dart';
import 'package:frontend/models/attendance_models.dart';
import 'package:frontend/models/lab_stay_models.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/auth_service.dart';

/// 실험실 체류 조회 서비스 - 최근 7일, 30일
class LabStayService {
  LabStayService._();

  static final LabStayService _instance = LabStayService._();
  static LabStayService get instance => _instance;

  final ApiClient _client = ApiClient.instance;

  /// 최근 7일 체크인/체크아웃 조회
  Future<List<StayRecord>> getLast7Days() async {
    final res = await _client.get(ApiConfig.stayWeek);

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final apiRes = ApiResponse.fromJson(
        json,
        (d) {
          if (d is List) {
            return d
                .map((e) => StayRecord.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return <StayRecord>[];
        },
      );
      return apiRes.data ?? [];
    }
    throw ApiException('체류 기록 조회에 실패했습니다. (${res.statusCode})');
  }

  /// 최근 30일 하루별 체류 시간 조회
  Future<List<DailyStayRecord>> getLast30Days() async {
    final res = await _client.get(ApiConfig.stayMonth);

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final apiRes = ApiResponse.fromJson(
        json,
        (d) {
          if (d is List) {
            return d
                .map((e) =>
                    DailyStayRecord.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return <DailyStayRecord>[];
        },
      );
      return apiRes.data ?? [];
    }
    throw ApiException('체류 기록 조회에 실패했습니다. (${res.statusCode})');
  }
}
