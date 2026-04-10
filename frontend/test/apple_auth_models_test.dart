import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/auth_models.dart';

void main() {
  group('LoginResponseDto (애플/로그인 공통 응답 파싱)', () {
    test('accessToken 키', () {
      final dto = LoginResponseDto.fromJson({
        'accessToken': 'jwt-a',
        'memberId': 20241234,
        'username': '홍길동',
        'phone': '010-1',
        'email': 'a@b.c',
      });
      expect(dto.accessToken, 'jwt-a');
      expect(dto.memberId, 20241234);
    });

    test('access_token 별칭', () {
      final dto = LoginResponseDto.fromJson({
        'access_token': 'jwt-b',
        'memberId': 1,
        'username': 'u',
        'phone': 'p',
        'email': 'e@e.e',
      });
      expect(dto.accessToken, 'jwt-b');
    });

    test('data 래핑 안의 token (루트에 memberId)', () {
      final dto = LoginResponseDto.fromJson({
        'data': {'token': 'jwt-c'},
        'memberId': 99,
        'username': 'n',
        'phone': '010',
        'email': 'x@y.z',
      });
      expect(dto.accessToken, 'jwt-c');
      expect(dto.memberId, 99);
    });
  });
}
