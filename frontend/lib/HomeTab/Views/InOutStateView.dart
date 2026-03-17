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
    final mm = value.month.toString().padLeft(2, '0');
    final dd = value.day.toString().padLeft(2, '0');
    final hh = value.hour.toString().padLeft(2, '0');
    final mi = value.minute.toString().padLeft(2, '0');
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
      _lastCheckInAt = DateTime.now();
      await _persistAttendanceState();
      widget.onStatusUpdated?.call(_lastCheckInAt);
      _showSnackBar('체크인되었습니다.');
    } on ApiException catch (e) {
      final alreadyCheckedIn = e.message.contains('이미 체크인');
      if (alreadyCheckedIn) {
        _currentStatus = LabStatus.inLab;
        await _persistAttendanceState();
      }
      _showSnackBar(e.message);
    } catch (_) {
      _showSnackBar('체크인 중 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _checkOut() async {
    if (_isSubmitting || _isLoading || _currentStatus == LabStatus.outLab) return;
    if (_activeCheckInId == null) {
      _showSnackBar('체크아웃할 체크인 정보가 없어 진행할 수 없습니다.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await AttendanceService.instance.checkOut(_activeCheckInId!);
      _currentStatus = LabStatus.outLab;
      _activeCheckInId = null;
      _lastCheckOutAt = DateTime.now();
      await _persistAttendanceState();
      widget.onStatusUpdated?.call(null);
      _showSnackBar('체크아웃되었습니다.');
    } on ApiException catch (e) {
      _showSnackBar(e.message);
    } catch (_) {
      _showSnackBar('체크아웃 중 오류가 발생했습니다.');
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
import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/services/lab_stay_service.dart'; // 💡 LabStayService 임포트 확인
import 'dart:convert';
import 'package:intl/intl.dart';

enum LabStatus { inLab, outLab }

class LabStatusCard extends StatefulWidget {
  final Function(DateTime?)? onStatusUpdated;
  const LabStatusCard({super.key, this.onStatusUpdated});

  @override
  State<LabStatusCard> createState() => LabStatusCardState();
}

// 💡 1. AutomaticKeepAliveClientMixin 추가 (화면 전환 시 상태 유지)
class LabStatusCardState extends State<LabStatusCard> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {

  // 💡 2. wantKeepAlive를 true로 설정
  @override
  bool get wantKeepAlive => true;

  LabStatus _currentStatus = LabStatus.outLab;
  String _lastCheckTime = '기록 없음';
  bool _isLoading = true; // 💡 처음 로딩 시 서버 상태를 확인해야 하므로 true로 시작
  int? _currentCheckInId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 💡 3. 위젯이 생성될 때 서버로부터 현재 실제 상태를 가져옴
    _syncStatusWithServer();
  }

  // 💡 4. 서버와 현재 상태 동기화 함수
  Future<void> _syncStatusWithServer() async {
    try {
      final bool isEntered = await LabStayService.instance.getIsEntered();
      if (mounted) {
        setState(() {
          _currentStatus = isEntered ? LabStatus.inLab : LabStatus.outLab;
          _isLoading = false;
          if (isEntered) {
            _lastCheckTime = "실험실 체류 중";
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("초기 상태 동기화 실패: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      autoCheckOut();
    }
  }

  Future<void> autoCheckOut() async {
    if (_currentStatus == LabStatus.inLab) {
      try {
        await LabStayService.instance.checkOut();
      } catch (e) {
        debugPrint("자동 체크아웃 실패: $e");
      }
    }
  }

  Future<void> _updateStatus(LabStatus newStatus) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      bool success = false;
      if (newStatus == LabStatus.inLab) {
        success = await LabStayService.instance.checkIn();
      } else {
        success = await LabStayService.instance.checkOut();
      }

      if (success) {
        setState(() {
          _currentStatus = newStatus;
          _lastCheckTime = DateFormat('MM월 dd일 HH:mm').format(DateTime.now());
          _isLoading = false;
        });
        widget.onStatusUpdated?.call(newStatus == LabStatus.inLab ? DateTime.now() : null);
      } else {
        // 만약 실패했는데 "이미 체크인" 등의 사유라면 상태를 강제로 동기화
        _syncStatusWithServer();
      }
    } catch (e) {
      debugPrint("네트워크 오류: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 💡 5. Mixin 사용 시 필수 호출
    super.build(context);

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _CurrentStatusDisplay(status: _currentStatus, lastTime: _lastCheckTime),
            const SizedBox(height: 16),
            _isLoading
                ? const SizedBox(
                height: 48,
                child: Center(child: CircularProgressIndicator())
            )
                : _InOutButtons(currentStatus: _currentStatus, onUpdateStatus: _updateStatus),
          ],
        ),
      ),
    );
  }
}

class _CurrentStatusDisplay extends StatelessWidget {
  final LabStatus status;
  final String lastTime;
  const _CurrentStatusDisplay({required this.status, required this.lastTime});

  @override
  Widget build(BuildContext context) {
    final isIn = status == LabStatus.inLab;
    return Row(
      children: [
        Icon(
            isIn ? Icons.check_circle : Icons.error_outline,
            size: 48,
            color: isIn ? Colors.green : Colors.grey
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isIn ? '랩실 안에 있습니다' : '랩실 밖에 있습니다',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '상태: $lastTime',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}

class _InOutButtons extends StatelessWidget {
  final LabStatus currentStatus;
  final Function(LabStatus) onUpdateStatus;
  const _InOutButtons({required this.currentStatus, required this.onUpdateStatus});

  @override
  Widget build(BuildContext context) {
    final isIn = currentStatus == LabStatus.inLab;
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: isIn ? null : () => onUpdateStatus(LabStatus.inLab),
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
            onPressed: !isIn ? null : () => onUpdateStatus(LabStatus.outLab),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: isIn ? AppColors.primary : Colors.grey.shade300,
              ),
            ),
            child: const Text('나가기'),
          ),
        ),
      ],
    );
  }
}