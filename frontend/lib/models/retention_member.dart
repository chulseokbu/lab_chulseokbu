/// 잔류 현황 멤버 데이터
class RetentionMember {
  final String name;
  final String role;
  final String initial;
  final bool isPresent;
  final String? checkIn;
  final String? lastExit;
  final String? status;
  final String? duration;

  const RetentionMember({
    required this.name,
    required this.role,
    required this.initial,
    required this.isPresent,
    this.checkIn,
    this.lastExit,
    this.status,
    this.duration,
  });
}
