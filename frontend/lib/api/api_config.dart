/// API 설정
/// - Swagger: https://labchulseokbu-production.up.railway.app/swagger-ui/index.html
class ApiConfig {
  ApiConfig._();

  static const String baseUrl =
      'https://labchulseokbu-production.up.railway.app';

  // Member API
  static const String signup = '/lab/users/sign';
  static const String login = '/lab/users/login';
  static const String withdrawAccount = '/lab/users/me';

  /// Sign in with Apple — 서버에서 identityToken(JWT) 검증 후 기존 회원이면 로그인 응답과 동일한 본문.
  /// 미가입 시 HTTP 428 + `{ "needsProfile": true }` (404는 로그인 실패로만 처리).
  static const String appleAuth = '/lab/users/auth/apple';
  /// 애플 최초 연동 후 프로필(학번·이름·전화·이메일 등) 제출. 성공 시 로그인과 동일한 본문(accessToken 등).
  static const String appleCompleteProfile = '/lab/users/auth/apple/complete';

  // Lab Attendance API
  static const String checkIn = '/lab/attendance/in';
  static String checkOut(int inoutId) => '/lab/attendance/out/$inoutId';

  // Lab Stay API
  static const String stayWeek = '/lab/stay/week';
  static const String stayMonth = '/lab/stay/month';

  // Meeting API
  static const String meetings = '/lab/meetings';
  static const String joinMeeting = '/lab/meetings/join';
  static String meetingById(int meetingId) => '/lab/meetings/$meetingId';
  /// 탈퇴: POST …/leave (test 브랜치 backend 기준). 404면 Railway가 test의 최신 backend를 배포했는지 확인.
  static String meetingLeave(int meetingId) => '/lab/meetings/$meetingId/leave';
  static String meetingDelete(int meetingId) => '/lab/meetings/$meetingId';
  static String meetingDelegate(int meetingId) =>
      '/lab/meetings/$meetingId/delegate';
  static String meetingRetention(int meetingId) =>
      '/lab/meetings/$meetingId/retention';
  static String meetingStayWeek(int meetingId) =>
      '/lab/meetings/$meetingId/stay/week';
  static String meetingStayMonth(int meetingId) =>
      '/lab/meetings/$meetingId/stay/month';
}
