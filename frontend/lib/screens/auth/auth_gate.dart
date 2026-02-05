import 'package:flutter/material.dart';
import 'package:frontend/HomeTab/AuthTab/AuthScreen.dart';
import 'package:frontend/screens/home/home_page.dart';
import 'package:frontend/services/auth_service.dart';

/// 인증 게이트 - 로그인/회원가입/메인 화면 분기
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _isSigningUp = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final restored = await AuthService.instance.restoreSession();
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isLoggedIn = restored;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_isLoggedIn) {
      return HomePage(
        onLogout: () async {
          await AuthService.instance.logout();
          if (mounted) setState(() => _isLoggedIn = false);
        },
      );
    }
    if (_isSigningUp) {
      return SignUpScreen(onGoToLogin: () => setState(() => _isSigningUp = false));
    }
    return LoginScreen(
      onLoginSuccess: () => setState(() => _isLoggedIn = true),
      onGoToSignUp: () => setState(() => _isSigningUp = true),
    );
  }
}
