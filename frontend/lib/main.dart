import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/screens/auth/auth_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LabAttendanceApp());
}

class LabAttendanceApp extends StatelessWidget {
  const LabAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '랩실 출석부',
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}
