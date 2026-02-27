import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/Group_Tab/widgets/meeting_action_card.dart';
import 'package:frontend/Group_Tab/widgets/meeting_card.dart';
import 'package:frontend/HomeTab/Views/daily_status_view.dart';
import 'package:frontend/HomeTab/Views/Profile_Service.dart';
import 'package:frontend/models/meeting.dart';

class MeetingListScreen extends StatefulWidget {
  const MeetingListScreen({super.key});

  @override
  State<MeetingListScreen> createState() => _MeetingListScreenState();
}

class _MeetingListScreenState extends State<MeetingListScreen> {
  late List<Meeting> _meetings;

  @override
  void initState() {
    super.initState();
    _meetings = [
      Meeting(code: 'ABC123', name: 'AI 연구실', memberCount: 10, createdAt: '2024-01-15'),
      Meeting(code: 'XYZ789', name: '데이터과학 스터디', memberCount: 8, createdAt: '2024-02-01'),
    ];
  }

  void _showCreateMeetingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _InternalCreateMeetingDialog(
        onCreate: (String name, String code) {
          setState(() {
            _meetings.insert(0, Meeting(
              code: code,
              name: name,
              memberCount: 1,
              createdAt: DateTime.now().toString().substring(0, 10),
            ));
          });
        },
      ),
    );
  }

  // ... 기존 import 생략 ...

  // 모임 참여 다이얼로그 수정
  void _showJoinMeetingDialog() {
    final codeController = TextEditingController();
    bool isJoining = false; // 로딩 상태 관리용

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // 다이얼로그 내 로딩 상태 반영을 위해 사용
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('모임 참여'),
            content: TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: '모임 코드 입력',
                hintText: '초대 코드를 입력하세요',
                border: OutlineInputBorder(),
              ),
              enabled: !isJoining,
            ),
            actions: [
              TextButton(
                onPressed: isJoining ? null : () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: isJoining ? null : () async {
                  final code = codeController.text.trim();
                  if (code.isEmpty) return;

                  setDialogState(() => isJoining = true);

                  try {
                    final profileService = ProfileService();
                    final profile = await profileService.loadProfile();
                    final token = profile['accessToken'];

                    // 💡 Postman 코드를 Flutter 코드로 변환 적용
                    var headers = {
                      'Content-Type': 'application/json',
                      'Accept': '*/*',
                      'Authorization': 'Bearer $token' // 인증 토큰 추가
                    };

                    var response = await http.post(
                      Uri.parse('https://labchulseokbu-production.up.railway.app/lab/meetings/join'),
                      headers: headers,
                      body: json.encode({"code": code}),
                    );

                    final responseBody = utf8.decode(response.bodyBytes);
                    debugPrint("📊 참여 응답 상태코드: ${response.statusCode}");
                    debugPrint("📦 참여 응답 본문: $responseBody");

                    if (response.statusCode == 200 || response.statusCode == 201) {
                      final data = json.decode(responseBody);

                      // 서버 응답 구조에서 모임 정보 추출 (서버 응답 명세에 따라 수정 필요)
                      // 예시: data['data']['name'] 등
                      final meetingData = data['data'];

                      setState(() {
                        _meetings.insert(0, Meeting(
                          code: code,
                          name: meetingData['name'] ?? '새 참여 모임',
                          memberCount: meetingData['memberCount'] ?? 1,
                          createdAt: meetingData['createdAt'] ?? DateTime.now().toString().substring(0, 10),
                        ));
                      });

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('모임에 성공적으로 참여했습니다!')),
                        );
                      }
                    } else {
                      final errorData = json.decode(responseBody);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('참여 실패: ${errorData['message'] ?? '코드를 확인해주세요.'}')),
                        );
                      }
                    }
                  } catch (e) {
                    debugPrint("❌ 참여 에러: $e");
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
                      );
                    }
                  } finally {
                    if (mounted) setDialogState(() => isJoining = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: isJoining
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('참여하기', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
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
              const Text('내 모임', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: MeetingActionCard(icon: Icons.arrow_forward_ios, label: '모임 참여', isPrimary: false, onTap: _showJoinMeetingDialog)),
                  const SizedBox(width: 12),
                  Expanded(child: MeetingActionCard(icon: Icons.add, label: '모임 생성', isPrimary: true, onTap: _showCreateMeetingDialog)),
                ],
              ),
              const SizedBox(height: 24),
              ..._meetings.map((meeting) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: MeetingCard(
                  meeting: meeting,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DailyStatusView())),
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

class _InternalCreateMeetingDialog extends StatefulWidget {
  final Function(String name, String code) onCreate;
  const _InternalCreateMeetingDialog({required this.onCreate});

  @override
  State<_InternalCreateMeetingDialog> createState() => _InternalCreateMeetingDialogState();
}

class _InternalCreateMeetingDialogState extends State<_InternalCreateMeetingDialog> {
  final TextEditingController _nameController = TextEditingController();
  String? _serverCode;
  bool _isLoading = false;

  Future<void> _handleGenerateCode() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final profileService = ProfileService();
      final profile = await profileService.loadProfile();
      final token = profile['accessToken'];

      const String apiUrl = 'https://labchulseokbu-production.up.railway.app/lab/meetings';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({"name": name}),
      );

      final responseBody = utf8.decode(response.bodyBytes);
      debugPrint("📊 응답본문 확인: $responseBody");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(responseBody);
        setState(() {
          // 💡 로그에 찍힌 구조에 맞춰 data['data']['code'] 로 수정
          _serverCode = data['data']['code']?.toString();
        });
      }
    } catch (e) {
      debugPrint("❌ 에러: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text('새 모임 생성', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '모임 이름',
              hintText: '이름을 입력하세요',
              border: OutlineInputBorder(),
            ),
            enabled: _serverCode == null && !_isLoading,
          ),
          const SizedBox(height: 20),

          // 코드가 생성되었을 때만 보여주는 결과창
          if (_serverCode != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryAlt, width: 2),
              ),
              child: Column(
                children: [
                  const Text('생성된 초대 코드', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  SelectableText(
                    _serverCode!,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryAlt,
                        letterSpacing: 4
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        // 취소 버튼
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey))
        ),

        // 💡 버튼 분리 로직
        if (_serverCode == null)
        // 코드가 없을 때는 [코드 생성하기] 버튼
          ElevatedButton(
            onPressed: _isLoading ? null : _handleGenerateCode,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAlt),
            child: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('코드 생성하기', style: TextStyle(color: Colors.white)),
          )
        else
        // 코드가 생겼을 때는 [모임 생성하기] 버튼
          ElevatedButton(
            onPressed: () {
              widget.onCreate(_nameController.text.trim(), _serverCode!);
              Navigator.pop(context); // 닫히면서 메인 화면 리스트 업데이트
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('모임 생성하기', style: TextStyle(color: Colors.white)),
          ),
      ],
    );
  }
}