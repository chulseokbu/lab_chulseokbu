import 'package:flutter/foundation.dart';

/// 한국 기준(KST, UTC+9) 달력·시각 처리.
/// 서버 `LocalDate` / `LocalTime`(타임존 없음)은 **한국 현지** 값으로 가정한다.
class KstCalendar {
  KstCalendar._();

  static const int _kstOffsetMs = 9 * 60 * 60 * 1000;

  /// [instant] 시각이 가리키는 순간의 KST **달력** yyyy-MM-dd
  static String ymdFromInstant(DateTime instant) {
    final ms = instant.millisecondsSinceEpoch + _kstOffsetMs;
    final u = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    return '${u.year}-${u.month.toString().padLeft(2, '0')}-${u.day.toString().padLeft(2, '0')}';
  }

  /// KST 기준 오늘을 끝으로 연속 [n]일(포함), **오래된 날 → 오늘** 순서
  static List<String> consecutiveKstYmdEndingToday(int n) {
    final today = ymdFromInstant(DateTime.now());
    final p = today.split('-').map(int.parse).toList();
    final end = DateTime.utc(p[0], p[1], p[2]);
    return List.generate(n, (i) {
      final d = end.subtract(Duration(days: (n - 1) - i));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    });
  }

  static bool _hasExplicitTimeZone(String t) {
    final s = t.trim();
    if (s.endsWith('Z')) return true;
    return RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(s);
  }

  /// 타임존 없는 `...T...` 는 KST wall 로 파싱
  static DateTime? tryParseApiDateTime(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    if (_hasExplicitTimeZone(t)) return DateTime.tryParse(t);
    if (t.contains('T')) {
      return DateTime.tryParse('$t+09:00') ?? DateTime.tryParse(t);
    }
    return DateTime.tryParse(t);
  }

  /// API `date` 필드 → KST 기준 yyyy-MM-dd (`LocalDate` 는 그대로)
  static String apiDateToKstYmd(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return text;

    final head = text.split('T').first;
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(head)) {
      if (!text.contains('T')) return head;
    }

    if (text.contains('T') || text.contains(' ') || text.contains('Z')) {
      final normalized = text.contains(' ') && !text.contains('T')
          ? text.replaceFirst(' ', 'T')
          : text;
      final parsed = tryParseApiDateTime(normalized);
      if (parsed != null) {
        return ymdFromInstant(parsed.toUtc());
      }
    }

    return head;
  }

  /// UTC 순간 → 그때의 한국 **벽시계** 시:분 (날짜 넘김은 시·분만 쓸 때 모듈로 처리)
  static String kstHHmmFromUtcInstant(DateTime utcInstant) {
    final u = utcInstant.toUtc();
    var carry = u.hour * 60 + u.minute + 9 * 60;
    carry %= 24 * 60;
    if (carry < 0) carry += 24 * 60;
    final h = carry ~/ 60;
    final m = carry % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// 퇴실 등 날짜+시각 (ISO 또는 `yyyy-MM-dd HH:mm`)
  static String formatDateTimeKstDisplay(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    var t = raw.trim();
    if (t.contains(' ') && !t.contains('T')) t = t.replaceFirst(' ', 'T');
    final parsed = DateTime.tryParse(t) ?? tryParseApiDateTime(t);
    if (parsed == null) return formatCheckTimeForDisplay(raw);
    final ymd = ymdFromInstant(parsed.toUtc());
    final p = ymd.split('-').map(int.parse).toList();
    final hm = kstHHmmFromUtcInstant(parsed.toUtc());
    return '${p[1]}월 ${p[2]}일 $hm';
  }

  /// 체크인/아웃 표시 — 서버가 `...+09:00` ISO 를 주면 그 순간의 KST 시:분.
  /// 순수 `HH:mm` 만 오는 **레거시**(UTC 시각이 LocalTime 으로 저장됨)는 [assumeUtcWallOnDate]에
  /// `yyyy-MM-dd` 를 넘기면 그날 UTC 벽시계로 해석 후 KST 로 표시.
  static String formatCheckTimeForDisplay(
    String? raw, {
    String? assumeUtcWallOnDate,
  }) {
    if (raw == null || raw.isEmpty) return '-';
    final t = raw.trim();

    if (t.contains('T') ||
        t.endsWith('Z') ||
        RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(t)) {
      final parsed = DateTime.tryParse(t);
      if (parsed != null) {
        return kstHHmmFromUtcInstant(parsed.toUtc());
      }
    }

    if (RegExp(r'^\d{4}-\d{2}-\d{2}[ T]').hasMatch(t)) {
      final norm = t.contains('T') ? t : t.replaceFirst(' ', 'T');
      final parsed = tryParseApiDateTime(norm) ?? DateTime.tryParse(norm);
      if (parsed != null) {
        return kstHHmmFromUtcInstant(parsed.toUtc());
      }
    }

    if (RegExp(r'^\d{1,2}:\d{2}').hasMatch(t)) {
      final p = t.split(':');
      final hh = int.tryParse(p[0]) ?? 0;
      final mm = int.tryParse(p[1]) ?? 0;
      if (assumeUtcWallOnDate != null &&
          RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(assumeUtcWallOnDate)) {
        final ymd = assumeUtcWallOnDate.split('-').map(int.parse).toList();
        final utcWall = DateTime.utc(ymd[0], ymd[1], ymd[2], hh, mm);
        return kstHHmmFromUtcInstant(utcWall);
      }
      return '${p[0].padLeft(2, '0')}:${p[1].padLeft(2, '0')}';
    }

    final parsed = tryParseApiDateTime(t) ?? DateTime.tryParse(t);
    if (parsed == null) return t;
    return kstHHmmFromUtcInstant(parsed.toUtc());
  }

  /// KST 달력 [y]-[m]-[d] 의 [hour]:[minute] 시각을 나타내는 UTC instant
  static DateTime utcInstantFromKstWall(int y, int m, int d, int hour, int minute) {
    return DateTime.utc(y, m, d, hour, minute).subtract(const Duration(hours: 9));
  }

  /// 체크인 시각(ISO+오프셋 권장)부터 경과 시간. 레거시 `HH:mm`만 오면 [legacyUtcWallOnDate]의 UTC 벽시계로 해석.
  static Duration? elapsedSinceCheckIn(
    String? checkIn, {
    String? legacyUtcWallOnDate,
  }) {
    if (checkIn == null || checkIn.isEmpty) return null;
    final t = checkIn.trim();
    DateTime? startUtc;
    if (t.contains('T') ||
        t.endsWith('Z') ||
        RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(t)) {
      startUtc = DateTime.tryParse(t)?.toUtc();
    } else if (RegExp(r'^\d{1,2}:\d{2}').hasMatch(t)) {
      final p = t.split(':');
      final hh = int.tryParse(p[0]) ?? 0;
      final mm = int.tryParse(p[1]) ?? 0;
      final ymdStr = legacyUtcWallOnDate ?? ymdFromInstant(DateTime.now());
      final ymd = ymdStr.split('-').map(int.parse).toList();
      startUtc = DateTime.utc(ymd[0], ymd[1], ymd[2], hh, mm);
    }
    if (startUtc == null) return null;
    final now = DateTime.now().toUtc();
    if (startUtc.isAfter(now)) {
      startUtc = startUtc.subtract(const Duration(days: 1));
    }
    return now.difference(startUtc);
  }

  /// 디버그용 짧은 로그 (전체 바디 대신 길이·요약)
  static void debugLogHttpFailure({
    required String tag,
    required int statusCode,
    required String body,
    String? url,
  }) {
    final snippet = body.length > 280 ? '${body.substring(0, 280)}…' : body;
    debugPrint(
      '$tag HTTP $statusCode${url != null ? ' url=$url' : ''} bodyLen=${body.length}',
    );
    if (body.isNotEmpty) debugPrint('$tag body: $snippet');
  }
}
