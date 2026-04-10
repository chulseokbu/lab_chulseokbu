import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/apple_auth_login_status.dart';

void main() {
  group('AppleAuthLoginStatus (애플 로그인 HTTP 분기)', () {
    test('200 → loggedIn', () {
      expect(
        AppleAuthLoginStatus.classify(200),
        AppleAuthLoginKind.loggedIn,
      );
    });
    test('428 → needsOnboarding', () {
      expect(
        AppleAuthLoginStatus.classify(428),
        AppleAuthLoginKind.needsOnboarding,
      );
    });
    test('404 → failed (온보딩 아님)', () {
      expect(
        AppleAuthLoginStatus.classify(404),
        AppleAuthLoginKind.failed,
      );
    });
    test('401 → failed', () {
      expect(
        AppleAuthLoginStatus.classify(401),
        AppleAuthLoginKind.failed,
      );
    });
  });
}
