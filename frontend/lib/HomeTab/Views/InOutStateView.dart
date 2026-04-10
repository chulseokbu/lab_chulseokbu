import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/services/attendance_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/lab_stay_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LabStatus { inLab, outLab }

class LabStatusCard extends StatefulWidget {
  final Function(DateTime?)? onStatusUpdated;
  const LabStatusCard({super.key, this.onStatusUpdated});

  @override
  State<LabStatusCard> createState() => LabStatusCardState();
}

class LabStatusCardState extends State<LabStatusCard>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  LabStatus _currentStatus = LabStatus.outLab;
  int? _activeCheckInId;
  bool _isLoading = true;
  bool _isSubmitting = false;
  DateTime? _lastCheckInAt;
  DateTime? _lastCheckOutAt;

  static const String _keyCurrentStatus = 'attendance_current_status';
  static const String _keyCheckInId = 'attendance_check_in_id';
  static const String _keyLastCheckInAt = 'attendance_last_check_in_at';
  static const String _keyLastCheckOutAt = 'attendance_last_check_out_at';

  DateTime _nowUtc() => DateTime.now().toUtc();

  DateTime _toKst(DateTime value) => value.toUtc().add(const Duration(hours: 9));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeState();
  }

  Future<void> _initializeState() async {
    await _restoreAttendanceState();
    await _syncStatusWithServer();
  }

  Future<void> _restoreAttendanceState() async {
    final prefs = await SharedPreferences.getInstance();
    final statusRaw = prefs.getString(_keyCurrentStatus);
    final checkInId = prefs.getInt(_keyCheckInId);
    final lastCheckInAtRaw = prefs.getString(_keyLastCheckInAt);
    final lastCheckOutAtRaw = prefs.getString(_keyLastCheckOutAt);

    if (!mounted) return;
    setState(() {
      _currentStatus =
          statusRaw == LabStatus.inLab.name ? LabStatus.inLab : LabStatus.outLab;
      _activeCheckInId = checkInId;
      _lastCheckInAt =
          lastCheckInAtRaw != null ? DateTime.tryParse(lastCheckInAtRaw) : null;
      _lastCheckOutAt =
          lastCheckOutAtRaw != null ? DateTime.tryParse(lastCheckOutAtRaw) : null;
      _isLoading = false;
    });
  }

  Future<void> _syncStatusWithServer() async {
    try {
      final isEntered = await LabStayService.instance.getIsEntered();
      if (!mounted) return;
      if (_currentStatus != (isEntered ? LabStatus.inLab : LabStatus.outLab)) {
        setState(() {
          _currentStatus = isEntered ? LabStatus.inLab : LabStatus.outLab;
          if (!isEntered) {
            _activeCheckInId = null;
          }
        });
        await _persistAttendanceState();
      }
    } catch (_) {
      // 서버 동기화 실패 시 로컬 상태를 유지한다.
    }
  }

  /// 홈 탭 당겨서 새로고침: 최근 체류 API로 입실 여부·체크인 시각을 서버 기준으로 맞춤
  /// (onStatusUpdated는 호출하지 않음 — HomePage에서 출석 카드 새로고침과 함께 처리)
  Future<void> refreshFromServer() async {
    if (!mounted) return;
    try {
      final records = await LabStayService.instance.getLast7Days();
      if (!mounted) return;
      if (records.isEmpty) {
        setState(() {
          _currentStatus = LabStatus.outLab;
          _activeCheckInId = null;
        });
        await _persistAttendanceState();
        return;
      }
      final last = records.first;
      final entered =
          last.checkIn != null && last.checkOut == null;
      DateTime? parsedCheckIn;
      if (last.checkIn != null) {
        parsedCheckIn = DateTime.tryParse(last.checkIn!);
      }
      setState(() {
        _currentStatus = entered ? LabStatus.inLab : LabStatus.outLab;
        if (!entered) {
          _activeCheckInId = null;
        } else if (parsedCheckIn != null) {
          _lastCheckInAt = parsedCheckIn;
        }
      });
      await _persistAttendanceState();
    } catch (_) {
      await _syncStatusWithServer();
    }
  }

  /// 알림 영역용: 현재 입실 중이면 마지막 체크인 시각
  DateTime? get checkInTimeForNotification =>
      _currentStatus == LabStatus.inLab ? _lastCheckInAt : null;

  Future<void> _persistAttendanceState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentStatus, _currentStatus.name);
    if (_activeCheckInId != null) {
      await prefs.setInt(_keyCheckInId, _activeCheckInId!);
    } else {
      await prefs.remove(_keyCheckInId);
    }
    if (_lastCheckInAt != null) {
      await prefs.setString(_keyLastCheckInAt, _lastCheckInAt!.toIso8601String());
    }
    if (_lastCheckOutAt != null) {
      await prefs.setString(_keyLastCheckOutAt, _lastCheckOutAt!.toIso8601String());
    }
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '-';
    final kst = _toKst(value);
    final mm = kst.month.toString().padLeft(2, '0');
    final dd = kst.day.toString().padLeft(2, '0');
    final hh = kst.hour.toString().padLeft(2, '0');
    final mi = kst.minute.toString().padLeft(2, '0');
    return '$mm/$dd $hh:$mi';
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _checkIn() async {
    if (_isSubmitting || _isLoading || _currentStatus == LabStatus.inLab) return;
    setState(() => _isSubmitting = true);
    try {
      final checkInId = await AttendanceService.instance.checkIn();
      _currentStatus = LabStatus.inLab;
      _activeCheckInId = checkInId;
      _lastCheckInAt = _nowUtc();
      await _persistAttendanceState();
      widget.onStatusUpdated?.call(_lastCheckInAt);
      _showSnackBar('체크인되었습니다.');
    } on ApiException catch (e) {
      final alreadyCheckedIn = e.message.contains('이미 체크인');
      if (alreadyCheckedIn) {
        _currentStatus = LabStatus.inLab;
        await _persistAttendanceState();
        widget.onStatusUpdated?.call(_lastCheckInAt);
      }
      debugPrint('[check-in] ${e.message}');
    } catch (e, st) {
      debugPrint('[check-in] $e\n$st');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _checkOut() async {
    if (_isSubmitting || _isLoading || _currentStatus == LabStatus.outLab) return;
    if (_activeCheckInId == null) {
      debugPrint('[check-out] activeCheckInId 없음');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await AttendanceService.instance.checkOut(_activeCheckInId!);
      _currentStatus = LabStatus.outLab;
      _activeCheckInId = null;
      _lastCheckOutAt = _nowUtc();
      await _persistAttendanceState();
      widget.onStatusUpdated?.call(null);
      _showSnackBar('체크아웃되었습니다.');
    } on ApiException catch (e) {
      debugPrint('[check-out] ${e.message}');
    } catch (e, st) {
      debugPrint('[check-out] $e\n$st');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> autoCheckOut() async {
    if (_currentStatus == LabStatus.inLab) {
      await _checkOut();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      autoCheckOut();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CurrentStatus(
              status: _currentStatus,
              isLoading: _isLoading,
              lastCheckInAtText: _formatDateTime(_lastCheckInAt),
              lastCheckOutAtText: _formatDateTime(_lastCheckOutAt),
            ),
            const SizedBox(height: 16),
            _InOutButtons(
              currentStatus: _currentStatus,
              isSubmitting: _isSubmitting || _isLoading,
              onCheckIn: _checkIn,
              onCheckOut: _checkOut,
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentStatus extends StatelessWidget {
  final LabStatus status;
  final bool isLoading;
  final String lastCheckInAtText;
  final String lastCheckOutAtText;

  const _CurrentStatus({
    required this.status,
    required this.isLoading,
    required this.lastCheckInAtText,
    required this.lastCheckOutAtText,
  });

  @override
  Widget build(BuildContext context) {
    final isInLab = status == LabStatus.inLab;
    final statusText = isInLab ? '랩실 안에 있습니다' : '랩실 밖에 있습니다';
    final statusDetail = isLoading
        ? '상태를 불러오는 중입니다...'
        : (isInLab
            ? '마지막 체크인: $lastCheckInAtText'
            : '마지막 체크아웃: $lastCheckOutAtText');
    final statusColor = isInLab ? Colors.green.shade600 : AppColors.grey;

    return Row(
      children: [
        Icon(Icons.schedule, size: 64, color: statusColor),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              statusText,
              style: TextStyle(
                fontSize: 15.3,
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              statusDetail,
              style: const TextStyle(fontSize: 11.9, color: AppColors.grey),
            ),
          ],
        ),
      ],
    );
  }
}

class _InOutButtons extends StatelessWidget {
  final LabStatus currentStatus;
  final bool isSubmitting;
  final Future<void> Function() onCheckIn;
  final Future<void> Function() onCheckOut;

  const _InOutButtons({
    required this.currentStatus,
    required this.isSubmitting,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  @override
  Widget build(BuildContext context) {
    final isInLab = currentStatus == LabStatus.inLab;
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: !isInLab && !isSubmitting ? onCheckIn : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: const Text('들어오기'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: isInLab && !isSubmitting ? onCheckOut : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: isInLab ? AppColors.primary : Colors.grey.shade300,
              ),
            ),
            child: const Text('나가기'),
          ),
        ),
      ],
    );
  }
}