import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/api/api_config.dart';
import 'package:frontend/core/kst_calendar.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/HomeTab/Views/Profile_Service.dart';
import 'package:frontend/models/meeting.dart' show Meeting, meetingRoleFromApi;
import 'package:frontend/models/retention_member.dart';

/// API에서 받은 잔류 행(체류 시간은 빌드 시 `_liveDuration`으로 계산)
class _RetentionRow {
  const _RetentionRow({
    required this.name,
    required this.initial,
    required this.isPresent,
    this.checkIn,
    this.lastExit,
    required this.roleLabel,
  });

  final String name;
  final String initial;
  final bool isPresent;
  final String? checkIn;
  final String? lastExit;
  final String roleLabel;
}

/// 잔류현황 탭 — 내 모임 목록 + 선택 모임의 `/retention` 실데이터
class RetentionStatusView extends StatefulWidget {
  const RetentionStatusView({super.key});

  @override
  State<RetentionStatusView> createState() => _RetentionStatusViewState();
}

class _RetentionStatusViewState extends State<RetentionStatusView> {
  List<Meeting> _meetings = [];
  int _selectedIndex = 0;
  List<_RetentionRow> _rows = [];

  bool _meetingsLoading = true;
  bool _retentionLoading = false;
  String? _meetingsError;
  String? _retentionError;

  Timer? _ticker;

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

  int? get _selectedMeetingId {
    if (_selectedIndex < 0 || _selectedIndex >= _meetings.length) return null;
    return _meetings[_selectedIndex].meetingId;
  }

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      if (_rows.any((r) => r.isPresent)) setState(() {});
    });
    _loadInitial();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final profile = await ProfileService().loadProfile();
    final token = profile['accessToken'];
    if (token == null) return null;
    final s = token.toString();
    if (s.isEmpty) return null;
    return s;
  }

  int? _parseMeetingId(Map<String, dynamic> map) {
    final dynamic rawId = map['meetingId'] ?? map['id'] ?? map['meeting_id'];
    if (rawId is int) return rawId;
    return int.tryParse(rawId?.toString() ?? '');
  }

  Future<void> _loadInitial() async {
    setState(() {
      _meetingsLoading = true;
      _meetingsError = null;
    });
    await _fetchMeetings();
    if (!mounted) return;
    setState(() => _meetingsLoading = false);
    if (_meetings.isNotEmpty) {
      await _fetchRetention(showSpinner: true);
    }
  }

  Future<void> _fetchMeetings() async {
    try {
      final token = await _getToken();
      if (token == null) {
        if (mounted) {
          setState(() {
            _meetings = [];
            _meetingsError = '로그인이 필요합니다.';
          });
        }
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.meetings}'),
        headers: {
          'Accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        if (mounted) {
          setState(() {
            _meetingsError = '모임 목록을 불러오지 못했습니다.';
            _meetings = [];
          });
        }
        return;
      }

      final decodedData = json.decode(utf8.decode(response.bodyBytes));
      final dynamic rawList =
          decodedData is List ? decodedData : decodedData['data'];
      final fetched = (rawList as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((m) {
            return Meeting(
              meetingId: _parseMeetingId(m),
              code: (m['inviteCode'] ?? m['code'] ?? '').toString(),
              name: m['name']?.toString() ?? '이름 없음',
              memberCount: m['memberCount'] as int? ?? 0,
              createdAt: m['createdAt']?.toString() ?? '',
              myRole: meetingRoleFromApi(m['myRole']),
            );
          })
          .where((Meeting x) => x.meetingId != null)
          .toList();

      if (!mounted) return;
      setState(() {
        _meetings = fetched;
        _meetingsError = null;
        if (_selectedIndex >= _meetings.length) _selectedIndex = 0;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _meetingsError = '네트워크 오류입니다.';
          _meetings = [];
        });
      }
    }
  }

  _RetentionRow _rowFromJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? '').toString();
    final initial0 = (json['initial'] ?? '').toString();
    final initial = initial0.isNotEmpty
        ? initial0
        : (name.isNotEmpty ? name[0] : '?');
    final isPresent = json['isPresent'] as bool? ?? false;
    final checkIn = json['checkIn']?.toString();
    final lastExit = json['lastExit']?.toString();

    String roleLabel = '';
    final roleRaw = json['role'] ?? json['meetingRole'];
    if (roleRaw != null) {
      final s = roleRaw.toString().toUpperCase();
      if (s == 'LEADER') {
        roleLabel = '모임장';
      } else if (s == 'MEMBER') {
        roleLabel = '구성원';
      } else if (roleRaw.toString().trim().isNotEmpty) {
        roleLabel = roleRaw.toString();
      }
    }

    return _RetentionRow(
      name: name,
      initial: initial,
      isPresent: isPresent,
      checkIn: checkIn,
      lastExit: lastExit,
      roleLabel: roleLabel,
    );
  }

  Future<void> _fetchRetention({bool showSpinner = false}) async {
    final id = _selectedMeetingId;
    if (id == null) {
      if (mounted) {
        setState(() {
          _rows = [];
          _retentionLoading = false;
        });
      }
      return;
    }

    if (showSpinner && mounted) {
      setState(() {
        _retentionLoading = true;
        _retentionError = null;
      });
    }

    try {
      final token = await _getToken();
      if (token == null) {
        if (mounted) {
          setState(() {
            _retentionLoading = false;
            _retentionError = '로그인이 필요합니다.';
            _rows = [];
          });
        }
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.meetingRetention(id)}'),
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
        final rows = raw
            .whereType<Map<String, dynamic>>()
            .map(_rowFromJson)
            .toList();
        if (!mounted) return;
        setState(() {
          _rows = rows;
          _retentionLoading = false;
          _retentionError = null;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _retentionLoading = false;
        _retentionError = serverMessage.isNotEmpty
            ? serverMessage
            : '잔류 현황을 불러오지 못했습니다.';
        _rows = [];
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _retentionLoading = false;
          _retentionError = '네트워크 오류입니다.';
          _rows = [];
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _fetchMeetings();
    if (!mounted) return;
    if (_meetings.isEmpty) {
      setState(() => _rows = []);
      return;
    }
    await _fetchRetention(showSpinner: false);
  }

  void _onSelectMeeting(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
      _rows = [];
      _retentionError = null;
    });
    _fetchRetention(showSpinner: true);
  }

  String _kstClockLine() {
    final hm = KstCalendar.kstHHmmFromUtcInstant(DateTime.now().toUtc());
    return '현재 $hm (KST) 기준';
  }

  RetentionMember _toDisplayMember(_RetentionRow r) {
    return RetentionMember(
      name: r.name,
      role: r.roleLabel,
      initial: r.initial,
      isPresent: r.isPresent,
      checkIn: r.checkIn,
      lastExit: r.lastExit,
      duration: r.isPresent ? _liveDuration(r.checkIn) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _rows.where((r) => r.isPresent).length;
    final totalCount = _rows.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
            children: [
              if (_meetingsLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (_meetingsError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Center(
                    child: Text(
                      _meetingsError!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else if (_meetings.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Center(
                    child: Text(
                      '가입한 모임이 없습니다.\n그룹 탭에서 모임에 참여해 보세요.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else ...[
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _meetings.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedIndex;
                      return _MeetingChip(
                        label: _meetings[index].name,
                        isSelected: isSelected,
                        onTap: () => _onSelectMeeting(index),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '랩실 잔류 현황',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$presentCount/$totalCount',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _kstClockLine(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '선택한 모임의 실시간 출석 인원입니다.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_retentionLoading && _rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else if (_retentionError != null && _rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        _retentionError!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else if (_rows.isEmpty && !_retentionLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        '구성원이 없습니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  )
                else ...[
                  if (_retentionLoading)
                    const LinearProgressIndicator(minHeight: 2),
                  ..._rows.map(
                    (r) => _MemberRetentionCard(
                      member: _toDisplayMember(r),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

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
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: isSelected ? null : Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black87,
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

class _MemberRetentionCard extends StatelessWidget {
  final RetentionMember member;

  const _MemberRetentionCard({required this.member});

  static const Color _checkInGreen = Color(0xFF2E7D32);
  static const Color _checkOutRed = Color(0xFFC62828);

  @override
  Widget build(BuildContext context) {
    final timeLine = member.isPresent
        ? '체크인 ${KstCalendar.formatCheckTimeForDisplay(member.checkIn, assumeUtcWallOnDate: KstCalendar.ymdFromInstant(DateTime.now()))}'
        : '퇴실 ${KstCalendar.formatDateTimeKstDisplay(member.lastExit)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.18),
            child: Text(
              member.initial,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
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
                      size: 18,
                      color: member.isPresent ? _checkInGreen : _checkOutRed,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        member.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                if (member.role.trim().isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    member.role,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  timeLine,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (member.isPresent && member.duration != null)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                member.duration!,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1976D2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
