/// 앱 설정
/// - useMockData: true면 목업 데이터 사용, false면 실제 API 호출
class AppConfig {
  AppConfig._();

  /// 현재 목업 데이터 사용 중. 서버 연결 시 false로 변경
  static const bool useMockData = true;
}
