import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 클립보드 복사 기능을 위해 필요
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/api/api_config.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/Group_Tab/widgets/meeting_action_card.dart';
import 'package:frontend/Group_Tab/widgets/meeting_card.dart';
import 'package:frontend/HomeTab/Views/daily_status_view.dart';
import 'package:frontend/HomeTab/Views/Profile_Service.dart';
import 'package:frontend/models/meeting.dart' show Meeting, meetingRoleFromApi;

class MeetingListScreen extends StatefulWidget {
  const MeetingListScreen({super.key});

  @override
  State<MeetingListScreen> createState() => _MeetingListScreenState();
}

class _MeetingListScreenState extends State<MeetingListScreen> {
  List<Meeting> _meetings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyMeetings();
  }

  Future<void> _fetchMyMeetings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final profileService = ProfileService();
      final profile = await profileService.loadProfile();
      final token = profile['accessToken'];

      if (token == null || token.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.meetings}'),
        headers: {
          'Accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(utf8.decode(response.bodyBytes));
        final dynamic rawList = decodedData is List ? decodedData : decodedData['data'];
        final List<dynamic> fetchedData = rawList ?? [];

        if (mounted) {
          setState(() {
            _meetings = fetchedData.map((m) {
              final map = m is Map<String, dynamic>
                  ? m
                  : <String, dynamic>{};
              return Meeting(
                meetingId: _parseMeetingId(map),
                code: (map['inviteCode'] ?? map['code'] ?? '').toString(),
                name: map['name']?.toString() ?? '닉네임 없음',
                memberCount: map['memberCount'] as int? ?? 0,
                createdAt: map['createdAt']?.toString() ?? '',
                myRole: meetingRoleFromApi(map['myRole']),
              );
            }).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("❌ 에러 발생: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int? _parseMeetingId(dynamic item) {
    if (item is! Map<String, dynamic>) return null;
    final dynamic rawId = item['meetingId'] ?? item['id'] ?? item['meeting_id'];
    if (rawId is int) return rawId;
    return int.tryParse(rawId?.toString() ?? '');
  }

  String _extractServerMessage(http.Response response) {
    try {
      final dynamic decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        return (decoded['message'] ?? '').toString().trim();
      }
    } catch (_) {}
    return '';
  }

  /// 모임 참여 등 디버깅용: 상태코드·본문·예외를 한 문자열로 묶는다.
  String _formatJoinDiagnostic({
    required int? statusCode,
    required String serverMessage,
    required String responseBody,
    String? clientException,
    String? requestUrl,
  }) {
    final b = StringBuffer();
    if (clientException != null && clientException.isNotEmpty) {
      b.writeln('=== 클라이언트 예외 ===');
      b.writeln(clientException);
      b.writeln();
    }
    if (requestUrl != null && requestUrl.isNotEmpty) {
      b.writeln('요청: $requestUrl');
    }
    if (statusCode != null) {
      b.writeln('HTTP 상태: $statusCode');
    }
    if (serverMessage.isNotEmpty) {
      b.writeln('서버 message: $serverMessage');
    }
    b.writeln('--- 응답 본문 ---');
    final body = responseBody.trim();
    b.writeln(body.isEmpty ? '(비어 있음)' : body);
    return b.toString().trim();
  }

  void _logJoinFailure(String summary, String detailText) {
    debugPrint('[join] $summary\n$detailText');
  }

  void _showCreateMeetingDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => _InternalCreateMeetingDialog(
        onCreate: (String name, String code) {
          _fetchMyMeetings();
        },
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
    );
  }

  void _showJoinMeetingDialog() {
    final codeController = TextEditingController();
    bool isJoining = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('모임 참여'),
            content: TextField(
              controller: codeController,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]')),
              ],
              decoration: InputDecoration(
                labelText: '모임 코드 입력',
                hintText: '초대 코드를 입력하세요',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              enabled: !isJoining,
            ),
            actions: [
              TextButton(
                onPressed:
                    isJoining ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: isJoining ? null : () async {
                  final code = codeController.text.trim();
                  if (code.isEmpty) return;
                  final joinUrl = '${ApiConfig.baseUrl}${ApiConfig.joinMeeting}';
                  setDialogState(() => isJoining = true);
                  try {
                    final profileService = ProfileService();
                    final profile = await profileService.loadProfile();
                    final token = profile['accessToken'];
                    if (token == null || token.toString().trim().isEmpty) {
                      if (!mounted) return;
                      Navigator.of(context, rootNavigator: true).pop();
                      _logJoinFailure(
                        '로그인이 필요합니다.',
                        _formatJoinDiagnostic(
                          statusCode: null,
                          serverMessage: '',
                          responseBody: '',
                          requestUrl: joinUrl,
                          clientException:
                              '저장된 accessToken이 없습니다. 로그인 후 다시 시도해 주세요.',
                        ),
                      );
                      return;
                    }

                    final response = await http.post(
                      Uri.parse(joinUrl),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer $token'
                      },
                      // Railway 프로덕션: code 필드 필수. 로컬/기타: inviteCode 병행.
                      body: json.encode({'code': code, 'inviteCode': code}),
                    );
                    final rawBody = utf8.decode(response.bodyBytes);
                    final message = _extractServerMessage(response);
                    final diagnostic = _formatJoinDiagnostic(
                      statusCode: response.statusCode,
                      serverMessage: message,
                      responseBody: rawBody,
                      requestUrl: joinUrl,
                    );

                    if (response.statusCode == 200 || response.statusCode == 201) {
                      if (!mounted) return;
                      Navigator.of(context, rootNavigator: true).pop();
                      await _fetchMyMeetings();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('모임 참여가 완료되었습니다.')),
                      );
                      return;
                    }

                    if (!mounted) return;
                    Navigator.of(context, rootNavigator: true).pop();

                    final bool isAlreadyJoined = response.statusCode == 409 ||
                        (response.statusCode == 400 &&
                            message.contains('이미') &&
                            (message.contains('참여') ||
                                message.contains('가입')));
                    if (isAlreadyJoined) {
                      _logJoinFailure('이미 이 모임에 참여 중입니다.', diagnostic);
                      return;
                    }

                    final bool isInvalidMeeting =
                        response.statusCode == 404 ||
                            message.contains('존재하지') ||
                            message.contains('유효하지');
                    if (isInvalidMeeting) {
                      _logJoinFailure(
                        '모임을 찾을 수 없거나 초대 코드가 올바르지 않습니다.',
                        diagnostic,
                      );
                      return;
                    }

                    _logJoinFailure(
                      message.isNotEmpty
                          ? message
                          : '모임 참여 요청이 실패했습니다. (HTTP ${response.statusCode})',
                      diagnostic,
                    );
                  } catch (e, st) {
                    debugPrint("Join Error: $e\n$st");
                    if (!mounted) return;
                    Navigator.of(context, rootNavigator: true).pop();
                    _logJoinFailure(
                      '네트워크 또는 클라이언트 오류가 발생했습니다.',
                      _formatJoinDiagnostic(
                        statusCode: null,
                        serverMessage: '',
                        responseBody: '',
                        requestUrl: joinUrl,
                        clientException: '$e\n\n$st',
                      ),
                    );
                  } finally {
                    if (mounted) {
                      try {
                        setDialogState(() => isJoining = false);
                      } catch (_) {}
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
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

  void _goMeetingDetail(Meeting meeting) {
    if (meeting.meetingId == null) {
      debugPrint('[meeting] meetingId 없음 — 목록 새로고침 필요');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DailyStatusView(meeting: meeting)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _fetchMyMeetings,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('내 모임', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: MeetingActionCard(icon: Icons.login_rounded, label: '모임 참여', isPrimary: false, onTap: _showJoinMeetingDialog)),
                    const SizedBox(width: 16),
                    Expanded(child: MeetingActionCard(icon: Icons.group_add_rounded, label: '모임 생성', isPrimary: true, onTap: _showCreateMeetingDialog)),
                  ],
                ),
                const SizedBox(height: 32),
                if (_meetings.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: Text('가입된 모임이 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                  )
                else
                  ..._meetings.map((meeting) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: MeetingCard(
                      meeting: meeting,
                      onTap: () => _goMeetingDetail(meeting),
                    ),
                  )),
                const SizedBox(height: 100),
              ],
            ),
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
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.meetings}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({"name": name}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final inner = data['data'];
        if (inner is Map<String, dynamic>) {
          final code = (inner['inviteCode'] ?? inner['code'])?.toString();
          if (code != null && code.isNotEmpty) {
            setState(() => _serverCode = code);
          }
        }
      }
    } catch (e) {
      debugPrint("❌ 생성 에러: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('새로운 모임 만들기', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              autofocus: true,
              style: const TextStyle(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: '모임 이름',
                hintText: '멋진 모임 이름을 지어주세요',
                floatingLabelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: Colors.grey.shade50,
                prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
              ),
              enabled: _serverCode == null && !_isLoading,
            ),
            const SizedBox(height: 20),
            if (_serverCode != null) ...[
              const Divider(height: 40),
              const Text('초대 코드가 생성되었습니다', style: TextStyle(fontSize: 14, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _serverCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('코드가 복사되었습니다: $_serverCode'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(20),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5, style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      Text(_serverCode!, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 8)),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text('터치하여 복사하기', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), foregroundColor: Colors.grey.shade600),
                    child: const Text('닫기', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : (_serverCode == null ? _handleGenerateCode : () {
                      widget.onCreate(_nameController.text.trim(), _serverCode!);
                      Navigator.pop(context);
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_serverCode == null ? '코드 생성' : '시작하기', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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