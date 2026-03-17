import 'dart:convert';
import 'package:flutter/foundation.dart'; // 💡 debugPrint를 사용하기 위해 추가
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

  /// 💡 체크인 API 호출
  Future<bool> checkIn() async {
    try {
      final res = await _client.post('/attendance/checkin');
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint("CheckIn API Error: $e");
      return false;
    }
  }

  /// 💡 체크아웃 API 호출
  Future<bool> checkOut() async {
    try {
      final res = await _client.post('/attendance/checkout');
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint("CheckOut API Error: $e");
      return false;
    }
  }

  /// 💡 현재 입실 여부 확인 (화면 전환 시 상태 유지용)
  Future<bool> getIsEntered() async {
    try {
      final records = await getLast7Days();
      if (records.isEmpty) return false;

      // 가장 최근 기록의 퇴실 시간(checkOut)이 없으면 현재 입실 중인 상태
      // (서버 응답 리스트의 첫 번째 요소가 최신 데이터라고 가정)
      final lastRecord = records.first;
      return lastRecord.checkIn != null && lastRecord.checkOut == null;
    } catch (e) {
      debugPrint("상태 조회 오류: $e");
      return false;
    }
  }

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