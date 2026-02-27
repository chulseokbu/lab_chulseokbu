import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static const String _nameKey = 'profile_name';
  static const String _studentIdKey = 'profile_student_id';
  static const String _phoneKey = 'profile_phone';
  static const String _emailKey = 'profile_email';
  static const String _userIdKey = 'user_id'; // 💡 int 타입으로 관리됨
  static const String _accessTokenKey = 'access_token';

  // 고유 정수 ID 생성 및 저장
  Future<int> generateAndSaveUniqueId() async {
    final prefs = await SharedPreferences.getInstance();

    // 💡 안전한 타입을 확인하기 위해 get() 사용
    Object? existingValue = prefs.get(_userIdKey);
    if (existingValue is int) return existingValue;

    int newId = Random().nextInt(900000) + 100000;
    await prefs.setInt(_userIdKey, newId);
    return newId;
  }

  // 프로필 정보를 SharedPreferences에 저장
  // 프로필 정보를 SharedPreferences에 저장
  // 프로필 정보를 SharedPreferences에 저장
  Future<void> saveProfile({
    required String name,
    required String studentId,
    required String phone,
    required String email,
    int? memberId, // 💡 String?에서 int?로 확정
    String? accessToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_nameKey, name);
    await prefs.setString(_studentIdKey, studentId);
    await prefs.setString(_phoneKey, phone);
    await prefs.setString(_emailKey, email);

    if (accessToken != null) {
      await prefs.setString(_accessTokenKey, accessToken);
    }

    if (memberId != null) {
      // 💡 userIdKey에는 항상 int로 저장 (타입 충돌 방지)
      await prefs.setInt(_userIdKey, memberId);
    }
    print("💾 로컬 저장 완료: 학번($studentId), 서버ID($memberId) 저장됨");
  }

  // 저장된 프로필 정보를 불러오기
  Future<Map<String, dynamic>> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'name': prefs.getString(_nameKey) ?? '미설정',
      'studentId': prefs.getString(_studentIdKey) ?? '0',
      'accessToken': prefs.getString(_accessTokenKey) ?? '',
      'phone': prefs.getString(_phoneKey) ?? '',
      'email': prefs.getString(_emailKey) ?? '',
      'userId': prefs.getInt(_userIdKey) ?? 0, // 💡 int 타입 반환
    };
  }

  // 데이터 초기화 (로그아웃 시 사용)
  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}