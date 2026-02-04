/// API 설정
/// - Swagger: https://labchulseokbu-production.up.railway.app/swagger-ui/index.html
class ApiConfig {
  ApiConfig._();

  static const String baseUrl =
      'https://labchulseokbu-production.up.railway.app';

  // Member API
  static const String signup = '/lab/users/sign';
  static const String login = '/lab/users/login';

  // Lab Attendance API
  static const String checkIn = '/lab/attendance/in';
  static String checkOut(int inoutId) => '/lab/attendance/out/$inoutId';

  // Lab Stay API
  static const String stayWeek = '/lab/stay/week';
  static const String stayMonth = '/lab/stay/month';
}
