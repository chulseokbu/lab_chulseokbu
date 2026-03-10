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