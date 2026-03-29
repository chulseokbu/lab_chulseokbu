/// 모임 데이터
class Meeting {
  final int? meetingId;
  final String code;
  final String name;
  final int memberCount;
  final String createdAt;

  Meeting({
    this.meetingId,
    required this.code,
    required this.name,
    required this.memberCount,
    required this.createdAt,
  });
}
