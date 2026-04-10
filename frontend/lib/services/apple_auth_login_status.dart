/// `POST /lab/users/auth/apple` 응답 코드 해석 — [AppleAuthService]와 테스트가 같은 규칙을 쓰도록 분리
enum AppleAuthLoginKind {
  loggedIn,
  needsOnboarding,
  failed,
}

class AppleAuthLoginStatus {
  AppleAuthLoginStatus._();

  static AppleAuthLoginKind classify(int statusCode) {
    if (statusCode == 200) return AppleAuthLoginKind.loggedIn;
    if (statusCode == 428) return AppleAuthLoginKind.needsOnboarding;
    return AppleAuthLoginKind.failed;
  }
}
