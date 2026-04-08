import 'package:flutter/material.dart';

/// 하루 **총 체류 시간** 기준 히트맵(잔디) 색상.
/// 홈 월간 API의 `duration` / `stayMinutes`와 모임 상세의 `stayMinutes`와 동일한 분 단위.
class StayHeatmap {
  StayHeatmap._();

  /// 1시간 미만 · 1~4시간 미만 · 4~8시간 미만 · 8시간 이상 (홈 탭 오렌지 스케일 통일)
  static Color colorForTotalMinutes(int minutes) {
    if (minutes <= 0) return Colors.grey.shade100;
    if (minutes < 60) return Colors.orange.shade200;
    if (minutes < 240) return Colors.orange.shade400;
    if (minutes < 480) return Colors.orange.shade600;
    return Colors.orange.shade800;
  }

  /// 월간 API `duration` 문자열 — 예: `0분`, `45분`, `2시간`, `2시간 30분`
  static int parseDurationToMinutes(String? duration) {
    if (duration == null || duration.isEmpty) return 0;
    final trimmed = duration.trim();
    if (trimmed == '0분') return 0;
    int total = 0;
    try {
      if (trimmed.contains('시간')) {
        final parts = trimmed.split('시간');
        total += (int.tryParse(parts[0].trim()) ?? 0) * 60;
        if (parts.length > 1) {
          final after = parts[1].replaceAll('분', '').trim();
          if (after.isNotEmpty) {
            total += int.tryParse(after) ?? 0;
          }
        }
      } else {
        total += int.tryParse(trimmed.replaceAll('분', '').trim()) ?? 0;
      }
    } catch (_) {
      return 0;
    }
    return total;
  }

  static Color colorForDurationString(String? duration) {
    return colorForTotalMinutes(parseDurationToMinutes(duration));
  }

  /// 범례 스와치 — [colorForTotalMinutes] 단계와 동일 순서
  static List<Color> get legendColors => [
        Colors.grey.shade100,
        Colors.orange.shade200,
        Colors.orange.shade400,
        Colors.orange.shade600,
        Colors.orange.shade800,
      ];
}
