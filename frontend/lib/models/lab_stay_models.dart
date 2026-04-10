/// 최근 7일 체크인/체크아웃 기록 (스키마는 API 응답에 따라 조정)
class StayRecord {
  final String? date;
  final String? checkIn;
  final String? checkOut;

  StayRecord({
    this.date,
    this.checkIn,
    this.checkOut,
  });

  factory StayRecord.fromJson(Map<String, dynamic> json) => StayRecord(
        date: json['date'] as String?,
        checkIn: json['checkIn'] as String?,
        checkOut: json['checkOut'] as String?,
      );
}

/// 최근 30일 하루별 체류 시간 (스키마는 API 응답에 따라 조정)
class DailyStayRecord {
  final String? date;
  final String? duration; // "3시간 45분" 등

  DailyStayRecord({
    this.date,
    this.duration,
  });

  factory DailyStayRecord.fromJson(Map<String, dynamic> json) {
    final date = json['date'] as String?;
    String? duration = json['duration'] as String?;
    if (duration == null || duration.isEmpty) {
      final sm = json['stayMinutes'];
      final minutes = sm is int ? sm : int.tryParse(sm?.toString() ?? '') ?? 0;
      duration = _minutesToDurationLabel(minutes);
    }
    return DailyStayRecord(date: date, duration: duration);
  }

  static String _minutesToDurationLabel(int minutes) {
    if (minutes <= 0) return '0분';
    if (minutes < 60) return '$minutes분';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '$h시간';
    return '$h시간 $m분';
  }
}
