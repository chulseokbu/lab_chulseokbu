import 'dart:math';
import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/Group_Tab/widgets/create_meeting_dialog.dart';
import 'package:frontend/Group_Tab/widgets/meeting_action_card.dart';
import 'package:frontend/Group_Tab/widgets/meeting_card.dart';
import 'package:frontend/HomeTab/Views/daily_status_view.dart';
import 'package:frontend/models/meeting.dart';

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
      builder: (context) => CreateMeetingDialog(
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('참여'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    child: MeetingActionCard(
                      icon: Icons.arrow_forward_ios,
                      label: '모임 참여',
                      isPrimary: false,
                      onTap: _showJoinMeetingDialog,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MeetingActionCard(
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
                    child: MeetingCard(
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
