import 'package:flutter/material.dart';

const Color _mainOrange = Color(0xFFF97316);

/// 잔류 현황 멤버 데이터 (목업)
class RetentionMember {
  final String name;
  final String role;
  final String initial;
  final bool isPresent;
  final String? checkIn; // "09:15"
  final String? lastExit; // "어제 18:30" or "오늘 11:20"
  final String? status; // "작업 중", "휴식 중", "회의 중"
  final String? duration; // "3시간 45분"

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

/// 잔류현황 탭 화면
class RetentionStatusView extends StatefulWidget {
  const RetentionStatusView({super.key});

  @override
  State<RetentionStatusView> createState() => _RetentionStatusViewState();
}

class _RetentionStatusViewState extends State<RetentionStatusView> {
  static const List<String> _meetings = [
    'AI 연구실',
    '데이터과학 스터디',
    '머신러닝 세미나',
    '딥러닝 프로젝트',
  ];

  int _selectedMeetingIndex = 1; // 기본: 데이터과학 스터디

  static final List<RetentionMember> _mockMembers = [
    const RetentionMember(
      name: '김학생',
      role: '박사과정',
      initial: '김',
      isPresent: true,
      checkIn: '09:15',
      status: '작업 중',
      duration: '3시간 45분',
    ),
    const RetentionMember(
      name: '이연구',
      role: '석사과정',
      initial: '이',
      isPresent: true,
      checkIn: '08:30',
      status: '휴식 중',
      duration: '4시간 30분',
    ),
    const RetentionMember(
      name: '박조교',
      role: '연구원',
      initial: '박',
      isPresent: false,
      lastExit: '어제 18:30',
    ),
    const RetentionMember(
      name: '정박사',
      role: '박사과정',
      initial: '정',
      isPresent: true,
      checkIn: '10:05',
      status: '회의 중',
      duration: '2시간 55분',
    ),
    const RetentionMember(
      name: '최석사',
      role: '석사과정',
      initial: '최',
      isPresent: false,
      lastExit: '오늘 11:20',
    ),
    const RetentionMember(
      name: '한멤버',
      role: '석사과정',
      initial: '한',
      isPresent: true,
      checkIn: '09:00',
      status: '작업 중',
      duration: '4시간 00분',
    ),
    const RetentionMember(
      name: '조연구',
      role: '연구원',
      initial: '조',
      isPresent: true,
      checkIn: '10:30',
      status: '휴식 중',
      duration: '2시간 30분',
    ),
    const RetentionMember(
      name: '강학생',
      role: '박사과정',
      initial: '강',
      isPresent: true,
      checkIn: '08:45',
      status: '작업 중',
      duration: '4시간 15분',
    ),
    const RetentionMember(
      name: '윤석사',
      role: '석사과정',
      initial: '윤',
      isPresent: false,
      lastExit: '어제 17:00',
    ),
    const RetentionMember(
      name: '임박사',
      role: '박사과정',
      initial: '임',
      isPresent: false,
      lastExit: '오늘 12:00',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final presentCount = _mockMembers.where((m) => m.isPresent).length;
    final totalCount = _mockMembers.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 모임 선택 버튼 (가로 스크롤)
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _meetings.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final isSelected = index == _selectedMeetingIndex;
                    return _MeetingChip(
                      label: _meetings[index],
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedMeetingIndex = index),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // 헤더: 제목 + 출석 인원 pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '랩실 잔류 현황',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _mainOrange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$presentCount/$totalCount 명 출석',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _mainOrange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 정보 카드
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _mainOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: _mainOrange, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '현재 시간 13:00 기준',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '실시간 랩실 인원 현황입니다',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 멤버 카드 리스트
              ..._mockMembers.map((member) => _MemberRetentionCard(member: member)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 모임 선택 칩 (선택 시 주황 배경, 미선택 시 흰색 + 주황 점)
class _MeetingChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MeetingChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? _mainOrange : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: isSelected ? null : Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : _mainOrange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberRetentionCard extends StatelessWidget {
  final RetentionMember member;

  const _MemberRetentionCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 아바타 + 출석 상태 표시
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _mainOrange.withOpacity(0.2),
                child: Text(
                  member.initial,
                  style: const TextStyle(
                    color: _mainOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                left: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: member.isPresent ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Icon(
                    member.isPresent ? Icons.check : Icons.close,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // 이름, 역할, 체크인/퇴실
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member.role,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  member.isPresent
                      ? '체크인: ${member.checkIn}'
                      : '마지막 퇴실: ${member.lastExit}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // 상태 pill + 체류 시간 (출석 시만)
          if (member.isPresent && member.status != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildStatusPill(member.status!),
                if (member.duration != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '체류 시간: ${member.duration}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    final isBreak = status == '휴식 중';
    final bgColor = isBreak ? _mainOrange.withOpacity(0.2) : Colors.purple.withOpacity(0.15);
    final textColor = isBreak ? _mainOrange : Colors.purple.shade700;
    final icon = isBreak ? Icons.coffee : Icons.person;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
