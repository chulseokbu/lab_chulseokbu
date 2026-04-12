import 'dart:convert';

/// Apple이 [AuthorizationCredentialAppleID.email]에 주지 않을 때,
/// Sign in with Apple `identityToken`(JWT) payload의 `email` 클레임을 읽습니다.
String? readEmailFromAppleIdentityToken(String? identityTokenJwt) {
  if (identityTokenJwt == null || identityTokenJwt.isEmpty) return null;
  final parts = identityTokenJwt.split('.');
  if (parts.length < 2) return null;
  try {
    final normalized = base64Url.normalize(parts[1]);
    final map = jsonDecode(utf8.decode(base64Url.decode(normalized)))
        as Map<String, dynamic>;
    final email = map['email'];
    if (email is String && email.isNotEmpty) return email;
  } catch (_) {}
  return null;
}
