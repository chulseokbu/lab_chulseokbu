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
