/// 출석 기록 (일별)
class AttendanceRecord {
  final String date;
  final String status;
  final String checkIn;
  final String checkOut;

  const AttendanceRecord({
    required this.date,
    required this.status,
    required this.checkIn,
    required this.checkOut,
  });
}
