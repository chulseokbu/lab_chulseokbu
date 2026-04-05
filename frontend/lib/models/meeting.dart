/// 서버 MeetingRole: LEADER(모임장), MEMBER(구성원)
enum MeetingRole {
  leader,
  member,
}

MeetingRole? meetingRoleFromApi(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString().toUpperCase();
  if (s == 'LEADER') return MeetingRole.leader;
  if (s == 'MEMBER') return MeetingRole.member;
  return null;
}

/// 모임 데이터
class Meeting {
  final int? meetingId;
  /// 초대 코드(목록 API에는 없음 · 생성 직후 또는 상세에서만 사용)
  final String code;
  final String name;
  final int memberCount;
  final String createdAt;
  final MeetingRole? myRole;

  Meeting({
    this.meetingId,
    required this.code,
    required this.name,
    required this.memberCount,
    required this.createdAt,
    this.myRole,
  });
}
