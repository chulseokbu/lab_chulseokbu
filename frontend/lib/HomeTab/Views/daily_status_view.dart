import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/HomeTab/Views/Profile_Service.dart';
import 'package:frontend/api/api_config.dart';
import 'package:frontend/core/kst_calendar.dart';
import 'package:frontend/core/stay_heatmap.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/widgets/other_member_profile_sheet.dart';
import 'package:http/http.dart' as http;

class DailyStatusView extends StatefulWidget {
  const DailyStatusView({super.key, required this.meeting});

  final Meeting meeting;

  @override
  State<DailyStatusView> createState() => _DailyStatusViewState();
}

class _DailyStatusViewState extends State<DailyStatusView> {
  bool _isListView = false;
  bool _isLoadingMembers = true;
  bool _isLoadingDetail = false;
  List<_RetentionMember> _members = [];
  final Map<int, List<_MonthlyStayRecord>> _monthlyByMember = {};
  final Map<int, List<_WeeklyInOutRecord>> _weeklyByMember = {};
  final Set<int> _expandedMemberIds = {};
  Timer? _ticker;

  MeetingRole? _myRole;
  String? _inviteCode;
  List<_MeetingMemberRow> _meetingMembers = [];
  int? _myMemberId;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    _loadInitialData();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait<void>([
      _fetchRetention(),
      _fetchMeetingDetail(),
    ]);
    await _fetchMonthlyStay();
  }

  /// 당겨서 새로고침: 목록은 유지한 채 잔류·월간·(목록 모드 시) 주간 데이터를 다시 받는다.
  Future<void> _pullRefresh() async {
    await Future.wait<void>([
      _fetchRetention(silent: true),
      _fetchMeetingDetail(),
    ]);
    await _fetchMonthlyStay(force: true);
    if (_isListView) {
      await _fetchWeeklyStay(force: true);
    }
  }

  Future<void> _fetchMeetingDetail() async {
    final id = widget.meeting.meetingId;
    if (id == null) return;

    try {
      final token = await _getToken();
      final profile = await ProfileService().loadProfile();
      _myMemberId = int.tryParse(profile['memberId'] ?? '');

      if (token == null) {
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.meetingById(id)}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final raw = utf8.decode(response.bodyBytes);
      Map<String, dynamic>? decoded;
      try {
        final d = json.decode(raw);
        if (d is Map<String, dynamic>) decoded = d;
      } catch (_) {}

      if (response.statusCode == 200 && decoded != null) {
        final data = decoded['data'];
        if (data is Map<String, dynamic>) {
          final rawMembers = data['members'] as List<dynamic>? ?? [];
          setState(() {
            _myRole = meetingRoleFromApi(data['myRole'] ?? data['role']) ??
                widget.meeting.myRole;
            final code = (data['inviteCode'] ?? data['code'])?.toString();
            _inviteCode = (code != null && code.isNotEmpty) ? code : null;
            _meetingMembers = rawMembers
                .whereType<Map<String, dynamic>>()
                .map(_MeetingMemberRow.fromJson)
                .where((m) => m.memberId > 0)
                .toList();
          });
        }
      } else {
        KstCalendar.debugLogHttpFailure(
          tag: '[meeting detail]',
          statusCode: response.statusCode,
          body: raw,
          url: '${ApiConfig.baseUrl}${ApiConfig.meetingById(id)}',
        );
      }
    } catch (e, st) {
      debugPrint('[meeting detail] $e\n$st');
    }
  }

  bool get _isLeader {
    if (_myRole == MeetingRole.leader) return true;
    if (widget.meeting.myRole == MeetingRole.leader) return true;
    final myId = _myMemberId;
    if (myId != null) {
      for (final m in _meetingMembers) {
        if (m.memberId == myId && m.role == MeetingRole.leader) return true;
      }
    }
    return false;
  }

  MeetingRole? _meetingRoleForMemberId(int memberId) {
    for (final m in _meetingMembers) {
      if (m.memberId == memberId) return m.role;
    }
    return null;
  }

  void _showOtherMemberProfileFor(_RetentionMember member) {
    showOtherMemberProfile(
      context,
      displayName: member.name,
      initial: member.initial,
      meetingRole: _meetingRoleForMemberId(member.memberId),
      isPresent: member.isPresent,
      checkIn: member.checkIn,
      lastExit: member.lastExit,
    );
  }

  /// 모임 나가기 실패 시 사용자에게 보여 줄 한 줄 요약 (404·Spring 기본 에러 페이지 구분)
  String _leaveFailureSummary({
    required int statusCode,
    required String serverMessage,
    required String rawBody,
  }) {
    if (serverMessage.isNotEmpty) return serverMessage;

    final body = rawBody.toLowerCase();
    final looksLikeSpringNoHandler = statusCode == 404 &&
        body.contains('"error"') &&
        (body.contains('not found') || body.contains('"status":404'));

    if (looksLikeSpringNoHandler) {
      return '모임 나가기 요청이 404입니다. '
          'Railway가 이 저장소 test 브랜치의 backend 최신 빌드를 배포했는지, '
          'Swagger(/v3/api-docs)에 POST /lab/meetings/{id}/leave 가 있는지 확인해 주세요.';
    }

    return '모임 나가기에 실패했습니다. (HTTP $statusCode)';
  }

  String _formatMeetingApiDiagnostic({
    required String requestUrl,
    required int? statusCode,
    required String serverMessage,
    required String responseBody,
    String? clientException,
  }) {
    final b = StringBuffer();
    if (clientException != null && clientException.isNotEmpty) {
      b.writeln('=== 클라이언트 예외 ===');
      b.writeln(clientException);
      b.writeln();
    }
    b.writeln('요청: $requestUrl');
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

  void _logMeetingActionFailure({
    required String summary,
    required String detailText,
  }) {
    debugPrint('[meeting] $summary\n$detailText');
  }

  Future<void> _copyInviteCode() async {
    final code = _inviteCode;
    if (code == null || code.isEmpty) {
      debugPrint('[invite] 초대 코드 없음');
      return;
    }
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('초대 코드가 복사되었습니다.')),
      );
    }
  }

  Future<void> _postMeetingLeave() async {
    final id = widget.meeting.meetingId;
    final token = await _getToken();
    final url = id != null
        ? '${ApiConfig.baseUrl}${ApiConfig.meetingLeave(id)}'
        : '(meetingId 없음)';

    if (id == null || token == null) {
      if (!mounted) return;
      _logMeetingActionFailure(
        summary: '모임 나가기를 진행할 수 없습니다.',
        detailText: _formatMeetingApiDiagnostic(
          requestUrl: url,
          statusCode: null,
          serverMessage: '',
          responseBody: '',
          clientException: id == null
              ? 'meetingId가 없습니다.'
              : '로그인 토큰이 없습니다.',
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final rawBody = utf8.decode(response.bodyBytes);
      Map<String, dynamic>? decoded;
      try {
        final d = json.decode(rawBody);
        if (d is Map<String, dynamic>) decoded = d;
      } catch (_) {}

      final msg = decoded != null ? (decoded['message'] ?? '').toString() : '';
      final success =
          decoded != null && (decoded['success'] == true || decoded['success'] == 'true');

      if (response.statusCode == 204 ||
          (response.statusCode == 200 && success)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('모임에서 나갔습니다.')),
          );
          Navigator.pop(context);
        }
        return;
      }

      debugPrint('[leave] HTTP ${response.statusCode} $rawBody');
      if (!mounted) return;

      final summary = _leaveFailureSummary(
        statusCode: response.statusCode,
        serverMessage: msg,
        rawBody: rawBody,
      );

      _logMeetingActionFailure(
        summary: summary,
        detailText: _formatMeetingApiDiagnostic(
          requestUrl: url,
          statusCode: response.statusCode,
          serverMessage: msg,
          responseBody: rawBody,
        ),
      );
    } catch (e, st) {
      debugPrint('[leave] $e\n$st');
      if (!mounted) return;
      _logMeetingActionFailure(
        summary: '모임 나가기 중 오류가 발생했습니다.',
        detailText: _formatMeetingApiDiagnostic(
          requestUrl: url,
          statusCode: null,
          serverMessage: '',
          responseBody: '',
          clientException: '$e\n\n$st',
        ),
      );
    }
  }

  Future<void> _deleteMeeting() async {
    final id = widget.meeting.meetingId;
    final token = await _getToken();
    final url = id != null
        ? '${ApiConfig.baseUrl}${ApiConfig.meetingDelete(id)}'
        : '(meetingId 없음)';

    if (id == null || token == null) {
      if (!mounted) return;
      _logMeetingActionFailure(
        summary: '모임 삭제를 진행할 수 없습니다.',
        detailText: _formatMeetingApiDiagnostic(
          requestUrl: url,
          statusCode: null,
          serverMessage: '',
          responseBody: '',
          clientException: id == null
              ? 'meetingId가 없습니다.'
              : '로그인 토큰이 없습니다.',
        ),
      );
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final rawBody = utf8.decode(response.bodyBytes);
      Map<String, dynamic>? decoded;
      try {
        final d = json.decode(rawBody);
        if (d is Map<String, dynamic>) decoded = d;
      } catch (_) {}

      final msg = decoded != null ? (decoded['message'] ?? '').toString() : '';
      final success = decoded != null &&
          (decoded['success'] == true || decoded['success'] == 'true');

      if (response.statusCode == 204 ||
          (response.statusCode == 200 && success)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('모임이 삭제되었습니다.')),
          );
          Navigator.pop(context);
        }
        return;
      }

      debugPrint('[delete meeting] HTTP ${response.statusCode} $rawBody');
      if (!mounted) return;
      _logMeetingActionFailure(
        summary: msg.isNotEmpty
            ? msg
            : '모임 삭제에 실패했습니다. (HTTP ${response.statusCode})',
        detailText: _formatMeetingApiDiagnostic(
          requestUrl: url,
          statusCode: response.statusCode,
          serverMessage: msg,
          responseBody: rawBody,
        ),
      );
    } catch (e, st) {
      debugPrint('[delete meeting] $e\n$st');
      if (!mounted) return;
      _logMeetingActionFailure(
        summary: '모임 삭제 중 오류가 발생했습니다.',
        detailText: _formatMeetingApiDiagnostic(
          requestUrl: url,
          statusCode: null,
          serverMessage: '',
          responseBody: '',
          clientException: '$e\n\n$st',
        ),
      );
    }
  }

  Future<void> _delegateTo(int newLeaderMemberId) async {
    final id = widget.meeting.meetingId;
    final token = await _getToken();
    final url = id != null
        ? '${ApiConfig.baseUrl}${ApiConfig.meetingDelegate(id)}'
        : '(meetingId 없음)';

    if (id == null || token == null) {
      if (!mounted) return;
      _logMeetingActionFailure(
        summary: '위임 요청을 진행할 수 없습니다.',
        detailText: _formatMeetingApiDiagnostic(
          requestUrl: url,
          statusCode: null,
          serverMessage: '',
          responseBody: '',
          clientException: id == null
              ? 'meetingId가 없습니다.'
              : '로그인 토큰이 없습니다.',
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'newLeaderMemberId': newLeaderMemberId}),
      );
      final rawBody = utf8.decode(response.bodyBytes);
      Map<String, dynamic>? decoded;
      try {
        final d = json.decode(rawBody);
        if (d is Map<String, dynamic>) decoded = d;
      } catch (_) {}

      final msg = decoded != null ? (decoded['message'] ?? '').toString() : '';
      final success = decoded != null &&
          (decoded['success'] == true || decoded['success'] == 'true');

      if (response.statusCode == 204 ||
          (response.statusCode == 200 && success)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('모임장 권한을 위임했습니다.')),
          );
          await _fetchMeetingDetail();
          await _fetchRetention();
        }
        return;
      }

      debugPrint('[delegate] HTTP ${response.statusCode} $rawBody');
      if (!mounted) return;
      _logMeetingActionFailure(
        summary: msg.isNotEmpty
            ? msg
            : '모임장 위임에 실패했습니다. (HTTP ${response.statusCode})',
        detailText: _formatMeetingApiDiagnostic(
          requestUrl: url,
          statusCode: response.statusCode,
          serverMessage: msg,
          responseBody: rawBody,
        ),
      );
    } catch (e, st) {
      debugPrint('[delegate] $e\n$st');
      if (!mounted) return;
      _logMeetingActionFailure(
        summary: '모임장 위임 중 오류가 발생했습니다.',
        detailText: _formatMeetingApiDiagnostic(
          requestUrl: url,
          statusCode: null,
          serverMessage: '',
          responseBody: '',
          clientException: '$e\n\n$st',
        ),
      );
    }
  }

  Future<void> _confirmLeave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('모임 나가기'),
        content: const Text('이 모임에서 나가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
    if (ok == true) await _postMeetingLeave();
  }

  Future<void> _confirmDeleteMeeting() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('모임 삭제'),
        content: const Text('모임을 삭제하면 모든 구성원이 제거됩니다. 계속할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok == true) await _deleteMeeting();
  }

  Future<void> _showDelegateDialog() async {
    final myId = _myMemberId;
    if (myId == null || myId <= 0) {
      debugPrint('[delegate] 내 memberId 없음');
      return;
    }
    final candidates = _meetingMembers
        .where((m) => m.memberId != myId)
        .toList();
    if (candidates.isEmpty) {
      debugPrint('[delegate] 위임 후보 없음');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                '모임장 위임',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            ...candidates.map(
              (m) => ListTile(
                title: Text(
                    m.nickname.isNotEmpty ? m.nickname : '회원 #${m.memberId}'),
                subtitle: Text(
                  m.role == MeetingRole.leader ? '모임장' : '구성원',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _delegateTo(m.memberId);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _getToken() async {
    final profile = await ProfileService().loadProfile();
    final token = profile['accessToken'];
    if (token == null || token.isEmpty) return null;
    return token;
  }

  Future<void> _fetchRetention({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoadingMembers = true;
      });
    }

    try {
      final token = await _getToken();
      if (token == null) {
        debugPrint('[retention] 토큰 없음');
        if (!silent) {
          setState(() {
            _isLoadingMembers = false;
            _members = [];
          });
        }
        return;
      }

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.meetingRetention(widget.meeting.meetingId!)}',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> decoded =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final String serverMessage = (decoded['message'] ?? '').toString();

      if (response.statusCode == 200) {
        final List<dynamic> raw =
            (decoded['data'] as List<dynamic>? ?? <dynamic>[]);
        final members = raw
            .whereType<Map<String, dynamic>>()
            .map(_RetentionMember.fromJson)
            .toList();
        if (!mounted) return;
        setState(() {
          _members = members;
          if (!silent && members.isNotEmpty) {
            _expandedMemberIds
              ..clear()
              ..add(members.first.memberId);
          }
          if (!silent) _isLoadingMembers = false;
        });
        return;
      }

      debugPrint(
        '[retention] HTTP 실패 ${response.statusCode} $serverMessage',
      );
      if (!silent) {
        setState(() {
          _isLoadingMembers = false;
          _members = [];
        });
      }
    } catch (e, st) {
      debugPrint('[retention] $e\n$st');
      if (!silent) {
        setState(() {
          _isLoadingMembers = false;
          _members = [];
        });
      }
    }
  }

  Future<void> _fetchMonthlyStay({bool force = false}) async {
    if (_isLoadingDetail && !force) return;
    setState(() => _isLoadingDetail = true);
    try {
      final token = await _getToken();
      if (token == null) {
        setState(() => _isLoadingDetail = false);
        return;
      }

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.meetingStayMonth(widget.meeting.meetingId!)}',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final Map<String, dynamic> decoded =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final List<dynamic> raw =
          (decoded['data'] as List<dynamic>? ?? <dynamic>[]);

      final next = <int, List<_MonthlyStayRecord>>{};
      for (final item in raw.whereType<Map<String, dynamic>>()) {
        final int? memberId = _parseInt(item['memberId']);
        if (memberId == null) continue;
        final List<dynamic> records = item['records'] as List<dynamic>? ?? [];
        next[memberId] = records
            .whereType<Map<String, dynamic>>()
            .map(_MonthlyStayRecord.fromJson)
            .toList();
      }

      setState(() {
        _monthlyByMember
          ..clear()
          ..addAll(next);
        _isLoadingDetail = false;
      });
    } catch (_) {
      setState(() => _isLoadingDetail = false);
    }
  }

  Future<void> _fetchWeeklyStay({bool force = false}) async {
    if (_isLoadingDetail && !force) return;
    setState(() => _isLoadingDetail = true);
    try {
      final token = await _getToken();
      if (token == null) {
        setState(() => _isLoadingDetail = false);
        return;
      }

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.meetingStayWeek(widget.meeting.meetingId!)}',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final Map<String, dynamic> decoded =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final List<dynamic> raw =
          (decoded['data'] as List<dynamic>? ?? <dynamic>[]);

      final next = <int, List<_WeeklyInOutRecord>>{};
      for (final item in raw.whereType<Map<String, dynamic>>()) {
        final int? memberId = _parseInt(item['memberId']);
        if (memberId == null) continue;
        final List<dynamic> records = item['records'] as List<dynamic>? ?? [];
        next[memberId] = records
            .whereType<Map<String, dynamic>>()
            .map(_WeeklyInOutRecord.fromJson)
            .toList();
      }

      setState(() {
        _weeklyByMember
          ..clear()
          ..addAll(next);
        _isLoadingDetail = false;
      });
    } catch (_) {
      setState(() => _isLoadingDetail = false);
    }
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  Future<void> _onToggle(bool listMode) async {
    if (_isListView == listMode) return;
    setState(() => _isListView = listMode);

    if (listMode && _weeklyByMember.isEmpty) {
      await _fetchWeeklyStay();
    } else if (!listMode && _monthlyByMember.isEmpty) {
      await _fetchMonthlyStay();
    }
  }

  String _liveDuration(String? checkIn) {
    final diff = KstCalendar.elapsedSinceCheckIn(
      checkIn,
      legacyUtcWallOnDate: KstCalendar.ymdFromInstant(DateTime.now()),
    );
    if (diff == null) return '-';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h <= 0) return '$m분';
    return '$h시간 $m분';
  }

  int _attendanceRate(int memberId) {
    final records = _monthlyByMember[memberId] ?? [];
    if (records.isEmpty) return 0;
    final attended = records.where((e) => e.stayMinutes > 0).length;
    return ((attended / 30) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _pullRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              _buildLegendSection(),
              const SizedBox(height: 10),
              if (_isLoadingMembers)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_members.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(
                    child: Text(
                      '구성원이 없습니다.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ..._members.map(_buildMemberCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.pop(context),
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Text(
                widget.meeting.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            if (_isLeader &&
                _inviteCode != null &&
                _inviteCode!.isNotEmpty)
              IconButton(
                tooltip: '초대 코드 복사',
                icon: const Icon(Icons.copy_rounded, size: 20),
                onPressed: _copyInviteCode,
                visualDensity: VisualDensity.compact,
              ),
            _buildToggleButtons(),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 20),
              onSelected: (value) async {
                switch (value) {
                  case 'delegate':
                    await _showDelegateDialog();
                    break;
                  case 'leave':
                    await _confirmLeave();
                    break;
                  case 'delete':
                    await _confirmDeleteMeeting();
                    break;
                }
              },
              itemBuilder: (context) => [
                if (_isLeader)
                  const PopupMenuItem(
                    value: 'delegate',
                    child: Text('모임장 위임'),
                  ),
                const PopupMenuItem(
                  value: 'leave',
                  child: Text('모임 나가기'),
                ),
                if (_isLeader)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('모임 삭제'),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '랩실 구성원 출석 현황',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        if (_isLeader) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _showDelegateDialog,
              icon: const Icon(Icons.how_to_reg_outlined, size: 16),
              label: const Text('모임장 위임'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _toggleButton(
            icon: Icons.grid_view_rounded,
            selected: !_isListView,
            onTap: () => _onToggle(false),
          ),
          _toggleButton(
            icon: Icons.format_list_bulleted_rounded,
            selected: _isListView,
            onTap: () => _onToggle(true),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton({
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 16,
          color: selected ? Colors.black87 : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildLegendSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDE6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(
            '출석 빈도:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          ...StayHeatmap.legendColors.map(
            (c) => Container(
              width: 15,
              height: 15,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: c,
              ),
            ),
          ),
          const Spacer(),
          if (_isLoadingDetail)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(_RetentionMember member) {
    final isExpanded = _expandedMemberIds.contains(member.memberId);
    final percentage = _attendanceRate(member.memberId);
    void toggleExpanded() {
      setState(() {
        if (isExpanded) {
          _expandedMemberIds.remove(member.memberId);
        } else {
          _expandedMemberIds.add(member.memberId);
        }
      });
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showOtherMemberProfileFor(member),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                      child: Text(
                        member.initial,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: toggleExpanded,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        member.isPresent
                                            ? Icons.check_rounded
                                            : Icons.close_rounded,
                                        size: 17,
                                        color: member.isPresent
                                            ? const Color(0xFF2E7D32)
                                            : const Color(0xFFC62828),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          member.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    member.isPresent
                                        ? '체크인 ${KstCalendar.formatCheckTimeForDisplay(member.checkIn, assumeUtcWallOnDate: KstCalendar.ymdFromInstant(DateTime.now()))}'
                                        : '마지막 퇴실 ${KstCalendar.formatDateTimeKstDisplay(member.lastExit)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$percentage %',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  member.isPresent
                                      ? '잔류 ${_liveDuration(member.checkIn)}'
                                      : '출석률',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 2, top: 2),
                              child: Icon(
                                isExpanded
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                color: AppColors.textSecondary,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: _isListView
                  ? _buildWeeklyList(member.memberId)
                  : _buildMonthlyHeatmap(member.memberId),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthlyHeatmap(int memberId) {
    final records = _monthlyByMember[memberId] ?? [];
    final byDate = {
      for (final r in records) r.dateOnly: r.stayMinutes,
    };

    final dateKeys = KstCalendar.consecutiveKstYmdEndingToday(30);
    final dates = dateKeys.map((k) {
      final p = k.split('-').map(int.parse).toList();
      return DateTime.utc(p[0], p[1], p[2]);
    }).toList();

    String gridDateKey(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final leading = dates.first.weekday - 1;
    final cells = <DateTime?>[
      ...List<DateTime?>.filled(leading, null),
      ...dates,
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    final weekRows = <List<DateTime?>>[];
    for (var i = 0; i < cells.length; i += 7) {
      weekRows.add(cells.sublist(i, i + 7));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const double gap = 3;
        const double leftGutter = 28;
        const double rightGutter = 40;
        final maxW = constraints.maxWidth;
        double cell = 18;
        if (maxW.isFinite && maxW > leftGutter + rightGutter + 7 * gap) {
          cell = ((maxW - leftGutter - rightGutter - 7 * gap) / 7)
              .clamp(12.0, 24.0);
        }
        final gridW = 7 * (cell + gap);
        final blockW = leftGutter + gridW + rightGutter;

        Widget heatCell(DateTime? d) {
          final minutes = d == null ? 0 : (byDate[gridDateKey(d)] ?? 0);
          return Padding(
            padding: const EdgeInsets.all(gap / 2),
            child: Container(
              width: cell,
              height: cell,
              decoration: BoxDecoration(
                color: d == null
                    ? Colors.transparent
                    : StayHeatmap.colorForTotalMinutes(minutes),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }

        const weekdayStyle = TextStyle(fontSize: 11, color: Colors.grey);
        final heatColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: leftGutter,
                  child: const SizedBox.shrink(),
                ),
                SizedBox(
                  width: gridW,
                  child: const Row(
                    children: [
                      Expanded(
                          child: Center(child: Text('월', style: weekdayStyle))),
                      Expanded(
                          child: Center(child: Text('화', style: weekdayStyle))),
                      Expanded(
                          child: Center(child: Text('수', style: weekdayStyle))),
                      Expanded(
                          child: Center(child: Text('목', style: weekdayStyle))),
                      Expanded(
                          child: Center(child: Text('금', style: weekdayStyle))),
                      Expanded(
                          child: Center(child: Text('토', style: weekdayStyle))),
                      Expanded(
                          child: Center(child: Text('일', style: weekdayStyle))),
                    ],
                  ),
                ),
                const SizedBox(width: rightGutter),
              ],
            ),
            const SizedBox(height: 6),
            ...List.generate(weekRows.length, (weekIdx) {
              final row = weekRows[weekIdx];
              final rowMinutes = row.fold<int>(0, (sum, d) {
                if (d == null) return sum;
                final key = gridDateKey(d);
                return sum + (byDate[key] ?? 0);
              });
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: leftGutter,
                      child: Text(
                        '${weekIdx + 1}주',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: gridW,
                      child: Row(
                        children: row.map(heatCell).toList(),
                      ),
                    ),
                    SizedBox(
                      width: rightGutter,
                      child: Text(
                        rowMinutes <= 0
                            ? ''
                            : rowMinutes >= 60
                                ? '${(rowMinutes / 60).toStringAsFixed(1)}h'
                                : '${rowMinutes}m',
                        textAlign: TextAlign.right,
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );

        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: blockW,
            child: heatColumn,
          ),
        );
      },
    );
  }

  Widget _buildWeeklyList(int memberId) {
    final raw = _weeklyByMember[memberId] ?? [];
    final records = List<_WeeklyInOutRecord>.of(raw)
      ..sort((a, b) => b.date.compareTo(a.date));
    if (records.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        alignment: Alignment.center,
        child: const Text(
          '최근 7일 체크인/체크아웃 기록이 없습니다.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text('날짜', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('출석 여부', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('체크인', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('체크아웃', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ...records.map((record) {
          final present = record.checkIn != null && record.checkIn!.isNotEmpty;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(_friendlyDate(record.date), style: const TextStyle(fontSize: 13))),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: present ? const Color(0xFFD9F4D8) : const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        present ? '출석' : '미출석',
                        style: TextStyle(
                          fontSize: 12,
                          color: present ? const Color(0xFF167A33) : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    KstCalendar.formatCheckTimeForDisplay(
                      record.checkIn,
                      assumeUtcWallOnDate:
                          KstCalendar.apiDateToKstYmd(record.date),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    KstCalendar.formatCheckTimeForDisplay(
                      record.checkOut,
                      assumeUtcWallOnDate:
                          KstCalendar.apiDateToKstYmd(record.date),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _friendlyDate(String date) {
    final normalized = KstCalendar.apiDateToKstYmd(date);
    final parts = normalized.split('-');
    if (parts.length != 3) return normalized;
    return '${int.tryParse(parts[1]) ?? parts[1]}월 ${int.tryParse(parts[2]) ?? parts[2]}일';
  }
}

class _MeetingMemberRow {
  const _MeetingMemberRow({
    required this.memberId,
    required this.nickname,
    this.role,
  });

  final int memberId;
  final String nickname;
  final MeetingRole? role;

  factory _MeetingMemberRow.fromJson(Map<String, dynamic> json) {
    final idRaw = json['memberId'];
    final id = idRaw is int
        ? idRaw
        : int.tryParse(idRaw?.toString() ?? '') ?? 0;
    return _MeetingMemberRow(
      memberId: id,
      nickname: json['nickname']?.toString() ?? '',
      role: meetingRoleFromApi(json['role'] ?? json['meetingRole']),
    );
  }
}

class _RetentionMember {
  const _RetentionMember({
    required this.memberId,
    required this.name,
    required this.initial,
    required this.isPresent,
    this.checkIn,
    this.lastExit,
  });

  final int memberId;
  final String name;
  final String initial;
  final bool isPresent;
  final String? checkIn;
  final String? lastExit;

  factory _RetentionMember.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? '').toString();
    final initial = (json['initial'] ?? '').toString();
    String? pick(String a, String b) {
      final v = json[a] ?? json[b];
      if (v == null) return null;
      final s = v.toString();
      return s.isEmpty ? null : s;
    }

    final idRaw = json['memberId'];
    final parsedId = idRaw is int
        ? idRaw
        : int.tryParse(idRaw?.toString() ?? '') ?? 0;

    return _RetentionMember(
      memberId: parsedId,
      name: name,
      initial: initial.isNotEmpty ? initial : (name.isNotEmpty ? name[0] : '?'),
      isPresent: json['isPresent'] as bool? ?? false,
      checkIn: pick('checkIn', 'startTime'),
      lastExit: pick('lastExit', 'endTime'),
    );
  }
}

class _WeeklyInOutRecord {
  const _WeeklyInOutRecord({
    required this.date,
    this.checkIn,
    this.checkOut,
  });

  final String date;
  final String? checkIn;
  final String? checkOut;

  factory _WeeklyInOutRecord.fromJson(Map<String, dynamic> json) {
    String? pick(String a, String b) {
      final v = json[a] ?? json[b];
      if (v == null) return null;
      final s = v.toString();
      return s.isEmpty ? null : s;
    }

    final rawDate = (json['date'] ?? '').toString();
    final dateOnly = rawDate.contains('T') || rawDate.contains(' ')
        ? KstCalendar.apiDateToKstYmd(rawDate)
        : rawDate.split('T').first;

    return _WeeklyInOutRecord(
      date: dateOnly.isNotEmpty ? dateOnly : rawDate,
      checkIn: pick('checkIn', 'startTime'),
      checkOut: pick('checkOut', 'endTime'),
    );
  }
}

class _MonthlyStayRecord {
  const _MonthlyStayRecord({
    required this.dateOnly,
    required this.stayMinutes,
  });

  final String dateOnly;
  final int stayMinutes;

  factory _MonthlyStayRecord.fromJson(Map<String, dynamic> json) {
    final rawDate = (json['date'] ?? '').toString();
    final dateOnly = KstCalendar.apiDateToKstYmd(rawDate);
    final minutes = json['stayMinutes'] as int? ?? 0;
    return _MonthlyStayRecord(dateOnly: dateOnly, stayMinutes: minutes);
  }
}