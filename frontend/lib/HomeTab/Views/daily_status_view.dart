import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/HomeTab/Views/Profile_Service.dart';
import 'package:frontend/api/api_config.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/models/meeting.dart';
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
  String? _errorMessage;

  List<_RetentionMember> _members = [];
  final Map<int, List<_MonthlyStayRecord>> _monthlyByMember = {};
  final Map<int, List<_WeeklyInOutRecord>> _weeklyByMember = {};
  final Set<int> _expandedMemberIds = {};
  Timer? _ticker;

  DateTime _nowKst() => DateTime.now().toUtc().add(const Duration(hours: 9));

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
    await _fetchRetention();
    await _fetchMonthlyStay();
  }

  Future<String?> _getToken() async {
    final profile = await ProfileService().loadProfile();
    final token = profile['accessToken'];
    if (token == null || token.isEmpty) return null;
    return token;
  }

  Future<void> _fetchRetention() async {
    setState(() {
      _isLoadingMembers = true;
      _errorMessage = null;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _isLoadingMembers = false;
          _errorMessage = '로그인이 필요합니다.';
        });
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
        setState(() {
          _members = members;
          if (members.isNotEmpty) {
            _expandedMemberIds
              ..clear()
              ..add(members.first.memberId);
          }
          _isLoadingMembers = false;
        });
        return;
      }

      setState(() {
        _isLoadingMembers = false;
        _errorMessage = serverMessage.isNotEmpty
            ? serverMessage
            : '구성원 정보를 불러오지 못했습니다.';
      });
    } catch (_) {
      setState(() {
        _isLoadingMembers = false;
        _errorMessage = '네트워크 오류로 구성원 정보를 불러오지 못했습니다.';
      });
    }
  }

  Future<void> _fetchMonthlyStay() async {
    if (_isLoadingDetail) return;
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

  Future<void> _fetchWeeklyStay() async {
    if (_isLoadingDetail) return;
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
    if (checkIn == null || checkIn.isEmpty) return '-';
    final parts = checkIn.split(':');
    if (parts.length < 2) return '-';

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final now = _nowKst();
    var started = DateTime(now.year, now.month, now.day, hour, minute);
    if (started.isAfter(now)) {
      started = started.subtract(const Duration(days: 1));
    }

    final diff = now.difference(started);
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
          onRefresh: _loadInitialData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              _buildLegendSection(),
              const SizedBox(height: 14),
              if (_isLoadingMembers)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
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
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Text(
                widget.meeting.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            _buildToggleButtons(),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '랩실 구성원 출석 현황',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
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
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: selected ? Colors.black87 : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildLegendSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDE6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            '출석 빈도:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          ...[0.15, 0.3, 0.5, 0.7, 1.0].map(
            (o) => Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: AppColors.primary.withOpacity(o),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            if (expanded) {
              _expandedMemberIds.add(member.memberId);
            } else {
              _expandedMemberIds.remove(member.memberId);
            }
          });
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withOpacity(0.14),
              child: Text(
                member.initial,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    member.isPresent
                        ? '체크인 ${member.checkIn ?? '-'}'
                        : '마지막 퇴실 ${member.lastExit ?? '-'}',
                    style: const TextStyle(
                      fontSize: 12,
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
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  member.isPresent
                      ? '잔류 ${_liveDuration(member.checkIn)}'
                      : '출석률',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
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

    final now = _nowKst();
    final first = now.subtract(const Duration(days: 29));
    final dates = List.generate(
      30,
      (i) => DateTime(first.year, first.month, first.day + i),
    );
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

    return Column(
      children: [
        Row(
          children: const [
            SizedBox(width: 38),
            Expanded(child: Center(child: Text('월', style: TextStyle(fontSize: 11, color: Colors.grey)))),
            Expanded(child: Center(child: Text('화', style: TextStyle(fontSize: 11, color: Colors.grey)))),
            Expanded(child: Center(child: Text('수', style: TextStyle(fontSize: 11, color: Colors.grey)))),
            Expanded(child: Center(child: Text('목', style: TextStyle(fontSize: 11, color: Colors.grey)))),
            Expanded(child: Center(child: Text('금', style: TextStyle(fontSize: 11, color: Colors.grey)))),
            Expanded(child: Center(child: Text('토', style: TextStyle(fontSize: 11, color: Colors.grey)))),
            Expanded(child: Center(child: Text('일', style: TextStyle(fontSize: 11, color: Colors.grey)))),
            SizedBox(width: 42),
          ],
        ),
        const SizedBox(height: 6),
        ...List.generate(weekRows.length, (weekIdx) {
          final row = weekRows[weekIdx];
          final rowMinutes = row.fold<int>(0, (sum, d) {
            if (d == null) return sum;
            final key = _dateKey(d);
            return sum + (byDate[key] ?? 0);
          });
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 38,
                  child: Text(
                    '${weekIdx + 1}주차',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ...row.map((d) {
                  final minutes = d == null ? 0 : (byDate[_dateKey(d)] ?? 0);
                  return Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: d == null
                              ? Colors.transparent
                              : _heatColor(minutes),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  );
                }),
                SizedBox(
                  width: 42,
                  child: Text(
                    rowMinutes <= 0
                        ? ''
                        : rowMinutes >= 60
                            ? '${(rowMinutes / 60).toStringAsFixed(1)}h'
                            : '${rowMinutes}m',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWeeklyList(int memberId) {
    final records = _weeklyByMember[memberId] ?? [];
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
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFF0F1F3)),
              ),
            ),
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
                Expanded(flex: 2, child: Text(record.checkIn ?? '-', style: const TextStyle(fontSize: 13))),
                Expanded(flex: 2, child: Text(record.checkOut ?? '-', style: const TextStyle(fontSize: 13))),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _heatColor(int stayMinutes) {
    if (stayMinutes <= 0) return Colors.grey.shade100;
    if (stayMinutes < 60) return AppColors.primary.withOpacity(0.25);
    if (stayMinutes < 180) return AppColors.primary.withOpacity(0.5);
    if (stayMinutes < 300) return AppColors.primary.withOpacity(0.75);
    return AppColors.primary;
  }

  String _dateKey(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  String _friendlyDate(String date) {
    final normalized = _normalizeDateAsKst(date);
    final parts = normalized.split('-');
    if (parts.length != 3) return normalized;
    return '${int.tryParse(parts[1]) ?? parts[1]}월 ${int.tryParse(parts[2]) ?? parts[2]}일';
  }

  String _normalizeDateAsKst(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return text;

    if (text.contains('T') || text.contains('Z') || text.contains('+')) {
      final parsed = DateTime.tryParse(text);
      if (parsed != null) {
        final kst = parsed.toUtc().add(const Duration(hours: 9));
        final m = kst.month.toString().padLeft(2, '0');
        final d = kst.day.toString().padLeft(2, '0');
        return '${kst.year}-$m-$d';
      }
    }

    if (text.contains(' ')) {
      final converted = text.replaceFirst(' ', 'T');
      final parsed = DateTime.tryParse(converted);
      if (parsed != null) {
        final kst = parsed.toUtc().add(const Duration(hours: 9));
        final m = kst.month.toString().padLeft(2, '0');
        final d = kst.day.toString().padLeft(2, '0');
        return '${kst.year}-$m-$d';
      }
    }

    return text.split('T').first;
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
    return _RetentionMember(
      memberId: (json['memberId'] as int?) ?? 0,
      name: name,
      initial: initial.isNotEmpty ? initial : (name.isNotEmpty ? name[0] : '?'),
      isPresent: json['isPresent'] as bool? ?? false,
      checkIn: json['checkIn']?.toString(),
      lastExit: json['lastExit']?.toString(),
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
    return _WeeklyInOutRecord(
      date: (json['date'] ?? '').toString(),
      checkIn: json['checkIn']?.toString(),
      checkOut: json['checkOut']?.toString(),
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
    final dateOnly = _toKstDateOnly(rawDate);
    final minutes = json['stayMinutes'] as int? ?? 0;
    return _MonthlyStayRecord(dateOnly: dateOnly, stayMinutes: minutes);
  }

  static String _toKstDateOnly(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return text;

    if (text.contains('T') || text.contains('Z') || text.contains('+')) {
      final parsed = DateTime.tryParse(text);
      if (parsed != null) {
        final kst = parsed.toUtc().add(const Duration(hours: 9));
        final m = kst.month.toString().padLeft(2, '0');
        final d = kst.day.toString().padLeft(2, '0');
        return '${kst.year}-$m-$d';
      }
    }

    if (text.contains(' ')) {
      final parsed = DateTime.tryParse(text.replaceFirst(' ', 'T'));
      if (parsed != null) {
        final kst = parsed.toUtc().add(const Duration(hours: 9));
        final m = kst.month.toString().padLeft(2, '0');
        final d = kst.day.toString().padLeft(2, '0');
        return '${kst.year}-$m-$d';
      }
    }

    return text.split('T').first;
  }
}