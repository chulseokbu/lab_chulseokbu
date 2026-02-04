import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/HomeTab/Views/daily_status_view.dart';

const Color _mainOrange = Color(0xFFF97316);
const Color _backgroundColor = Color(0xFFF9FAFB);

/// 모임 데이터 모델
class Meeting {
  final String code;
  String name;
  final int memberCount;
  final String createdAt;

  Meeting({
    required this.code,
    required this.name,
    required this.memberCount,
    required this.createdAt,
  });
}

/// 모임 리스트 메인 화면 (모임 탭 클릭 시 첫 화면)
class MeetingListScreen extends StatefulWidget {
  const MeetingListScreen({super.key});

  @override
  State<MeetingListScreen> createState() => _MeetingListScreenState();
}

class _MeetingListScreenState extends State<MeetingListScreen> {
  // 더미 데이터 (이미지와 동일)
  late List<Meeting> _meetings;

  @override
  void initState() {
    super.initState();
    _meetings = [
      Meeting(
        code: 'ABC123',
        name: 'AI 연구실',
        memberCount: 10,
        createdAt: '2024-01-15',
      ),
      Meeting(
        code: 'XYZ789',
        name: '데이터과학 스터디',
        memberCount: 8,
        createdAt: '2024-02-01',
      ),
    ];
  }

  /// 6자리 랜덤 모임 코드 생성
  String _generateMeetingCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  void _showCreateMeetingDialog() {
    final generatedCode = _generateMeetingCode();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CreateMeetingDialog(
        initialName: 'AI 연구실',
        meetingCode: generatedCode,
        onCancel: () => Navigator.pop(context),
        onCreate: (name) {
          setState(() {
            _meetings.insert(
              0,
              Meeting(
                code: generatedCode,
                name: name,
                memberCount: 1,
                createdAt: DateTime.now().toString().substring(0, 10),
              ),
            );
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showJoinMeetingDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모임 참여'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: '모임 코드 입력',
            hintText: '초대 코드를 입력하세요',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = codeController.text.trim();
              Navigator.pop(context);
              if (code.isNotEmpty) {
                final existing = _meetings.where((m) => m.code == code).firstOrNull;
                if (existing != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('이미 참여 중인 모임입니다.')),
                  );
                } else {
                  setState(() {
                    _meetings.add(Meeting(
                      code: code,
                      name: '새 모임 ($code)',
                      memberCount: 1,
                      createdAt: DateTime.now().toString().substring(0, 10),
                    ));
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('모임에 참여했습니다.')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _mainOrange),
            child: const Text('참여'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 제목
              const Text(
                '내 모임',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '참여 중인 모임을 관리하세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // 모임 참여 / 모임 생성 카드
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.arrow_forward_ios,
                      label: '모임 참여',
                      isPrimary: false,
                      onTap: _showJoinMeetingDialog,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.add,
                      label: '모임 생성',
                      isPrimary: true,
                      onTap: _showCreateMeetingDialog,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 모임 리스트
              ..._meetings.map((meeting) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _MeetingCard(
                      meeting: meeting,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DailyStatusView(),
                          ),
                        );
                      },
                    ),
                  )),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

/// 액션 카드 (모임 참여 / 모임 생성)
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: isPrimary ? _mainOrange : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isPrimary ? null : Border.all(color: Colors.grey.shade300, width: 2, strokeAlign: BorderSide.strokeAlignInside),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : Colors.grey.shade600,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 모임 카드
class _MeetingCard extends StatelessWidget {
  final Meeting meeting;
  final VoidCallback onTap;

  const _MeetingCard({required this.meeting, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meeting.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people_outline, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${meeting.memberCount}명',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '생성일: ${meeting.createdAt}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  meeting.code,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 모임 생성 팝업 다이얼로그 (두 번째 이미지)
class _CreateMeetingDialog extends StatefulWidget {
  final String initialName;
  final String meetingCode;
  final VoidCallback onCancel;
  final void Function(String name) onCreate;

  const _CreateMeetingDialog({
    required this.initialName,
    required this.meetingCode,
    required this.onCancel,
    required this.onCreate,
  });

  @override
  State<_CreateMeetingDialog> createState() => _CreateMeetingDialogState();
}

class _CreateMeetingDialogState extends State<_CreateMeetingDialog> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.meetingCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('모임 코드가 복사되었습니다.'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 제목 + 닫기
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '모임 생성',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  onPressed: widget.onCancel,
                  icon: Icon(Icons.close, color: Colors.grey.shade600),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 모임 이름
            const Text(
              '모임 이름',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'AI 연구실',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _mainOrange, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 모임 코드
            const Text(
              '모임 코드',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _mainOrange, width: 2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.meetingCode,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _copyCode,
                    icon: const Icon(Icons.copy),
                    color: _mainOrange,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '이 코드를 공유하여 다른 사람들을 초대하세요',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 28),

            // 취소 / 생성하기 버튼
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: widget.onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final name = _nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('모임 이름을 입력해주세요.')),
                        );
                        return;
                      }
                      widget.onCreate(name);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _mainOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('생성하기'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
