import 'package:flutter/material.dart';

/// 앱 전역 색상 상수
class AppColors {
  AppColors._();

  // 메인
  static const Color primary = Color(0xFFF97316);
  static const Color primaryAlt = Color(0xFFE68840); // Auth 화면용

  // 배경
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);

  // 텍스트
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFFCCCCCC);

  // 그레이
  static const Color grey = Color(0xFF9CA3AF);
  static const Color lightGrey = Color(0xFFE5E7EB);
  static const Color dividerGrey = Color(0xFFECECEC);

  // 상태
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Auth 배경
  static const Color authBackground = Color(0xFFFFF7F0);
}
