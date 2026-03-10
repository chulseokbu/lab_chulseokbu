import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class ProfileService {
  // 💡 프로필 정보 저장
  Future<void> saveProfile({
    required String name,
    required String studentId, // 학번 (UI 및 관리용)
    String? phone,
    String? email,
    String? accessToken,
    int? memberId, // 서버 식별용 ID
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('name', name);
    await prefs.setString('studentId', studentId); // 학번 키값 고정

    if (phone != null) await prefs.setString('phone', phone);
    if (email != null) await prefs.setString('email', email);
    if (accessToken != null) await prefs.setString('accessToken', accessToken);
    if (memberId != null) await prefs.setInt('memberId', memberId);
  }

  // 💡 프로필 정보 로드
  Future<Map<String, String>> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'name': prefs.getString('name') ?? '',
      'studentId': prefs.getString('studentId') ?? '', // 학번 로드
      'phone': prefs.getString('phone') ?? '',
      'email': prefs.getString('email') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      // memberId는 int이므로 저장된 값을 찾아 문자열로 변환하여 반환 (Map 타입 일치를 위해)
      'memberId': prefs.getInt('memberId')?.toString() ?? '',
    };
  }

  // 💡 기기 고유 식별자 생성 및 저장 (기존 로직 유지)
  Future<void> generateAndSaveUniqueId() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('unique_id') == null) {
      String newId = _generateRandomString(12);
      await prefs.setString('unique_id', newId);
    }
  }

  String _generateRandomString(int len) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        len, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  // 💡 로그아웃 시 데이터 삭제
  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('name');
    await prefs.remove('studentId');
    await prefs.remove('phone');
    await prefs.remove('email');
    await prefs.remove('accessToken');
    await prefs.remove('memberId');
    // unique_id는 기기 식별용이므로 유지하거나 필요시 삭제
  }
}