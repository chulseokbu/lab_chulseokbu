import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';

/// 앱 테마
class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Pretendard';

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
    );
  }
}
