import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';

/// 앱 테마
class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Pretendard';

  static final RoundedRectangleBorder _dialogShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  );

  static ThemeData get light {
    final base = ThemeData(
      fontFamily: fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
    final appliedTextTheme = base.textTheme.apply(fontFamily: fontFamily);
    return base.copyWith(
      textTheme: appliedTextTheme,
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: fontFamily),
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: appliedTextTheme.titleLarge,
      ),
      // Dialog / AlertDialog: 흰 배경, M3 surface tint 제거, 앱 타이포·색상
      // (Flutter 3.38+ AlertDialog는 dialogTheme의 title/content/actionsPadding 사용)
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: _dialogShape,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: AppColors.textPrimary,
          height: 1.25,
        ),
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 15,
          color: AppColors.textSecondary,
          height: 1.45,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        barrierColor: const Color(0x99000000),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
