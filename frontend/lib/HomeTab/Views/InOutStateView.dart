import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:frontend/HomeTab/Views/Profile_Service.dart';

enum LabStatus { inLab, outLab }

class LabStatusCard extends StatefulWidget {
  final VoidCallback? onStatusUpdated;
  const LabStatusCard({super.key, this.onStatusUpdated});

  @override
  State<LabStatusCard> createState() => _LabStatusCardState();
}

class _LabStatusCardState extends State<LabStatusCard> {
  LabStatus _currentStatus = LabStatus.outLab;
  String _lastCheckTime = '기록 없음';
  bool _isLoading = false;

  // 💡 체크인 성공 시 서버에서 받은 ID (누적 시간을 위해 필수)
  int? _currentCheckInId;

  final ProfileService _profileService = ProfileService();

  Future<void> _updateStatusWithApi(LabStatus newStatus) async {
    if (_isLoading || _currentStatus == newStatus) return;
    setState(() => _isLoading = true);

    try {
      final profileData = await _profileService.loadProfile();
      final String? token = profileData['accessToken'];

      if (token == null || token.isEmpty) {
        throw Exception('인증 정보가 없습니다.');
      }

      String urlString;
      if (newStatus == LabStatus.inLab) {
        urlString = 'https://labchulseokbu-production.up.railway.app/lab/attendance/in';
      } else {
        // 💡 퇴실 시: /lab/attendance/out/{inoutId}
        if (_currentCheckInId == null) throw Exception('체크인 정보가 없습니다.');
        urlString = 'https://labchulseokbu-production.up.railway.app/lab/attendance/out/$_currentCheckInId';
      }

      final response = await http.post(
        Uri.parse(urlString),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseBody = utf8.decode(response.bodyBytes);
      final decodedData = json.decode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (newStatus == LabStatus.inLab) {
          // 💡 서버 응답에서 checkInId 추출 (로그 참고: data['checkInId'])
          _currentCheckInId = decodedData['data']['checkInId'];
        } else {
          _currentCheckInId = null; // 퇴실 시 초기화
        }

        final now = DateTime.now();
        final formattedTime = DateFormat('MM월 dd일 HH:mm').format(now);

        setState(() {
          _currentStatus = newStatus;
          _lastCheckTime = formattedTime;
        });

        // 💡 부모 위젯(HomePage)에 알려서 AttendanceStatusCard 새로고침
        widget.onStatusUpdated?.call();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(newStatus == LabStatus.inLab ? '체크인 성공!' : '체크아웃 성공!')),
          );
        }
      } else {
        throw Exception(decodedData['message'] ?? '오류 발생');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('랩실 상태', style: TextStyle(fontSize: 15.3, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // 💡 에러 해결: 클래스 생성자로 호출
            _CurrentStatusDisplay(status: _currentStatus, lastTime: _lastCheckTime),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: LinearProgressIndicator(color: AppColors.primary))
            else
            // 💡 에러 해결: 클래스 생성자로 호출
              _InOutButtons(
                currentStatus: _currentStatus,
                onUpdateStatus: _updateStatusWithApi,
              ),
          ],
        ),
      ),
    );
  }
}

// --- 하위 위젯 클래스 정의 (생성자로 호출됨) ---

class _CurrentStatusDisplay extends StatelessWidget {
  final LabStatus status;
  final String lastTime;
  const _CurrentStatusDisplay({required this.status, required this.lastTime});

  @override
  Widget build(BuildContext context) {
    final isInLab = status == LabStatus.inLab;
    final statusColor = isInLab ? Colors.green.shade600 : AppColors.grey;

    return Row(
      children: [
        Icon(Icons.schedule, size: 64, color: statusColor),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isInLab ? '랩실 안에 있습니다' : '랩실 밖에 있습니다',
                style: TextStyle(fontSize: 15.3, color: statusColor, fontWeight: FontWeight.bold)),
            Text(isInLab ? '마지막 체크인: $lastTime' : '마지막 체크아웃: $lastTime',
                style: const TextStyle(fontSize: 11.9, color: AppColors.grey)),
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
    final isInLab = currentStatus == LabStatus.inLab;
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => onUpdateStatus(LabStatus.inLab),
            icon: const Icon(Icons.login, size: 16),
            label: const Text('들어오기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: !isInLab ? AppColors.primary : AppColors.lightGrey,
              foregroundColor: !isInLab ? Colors.white : AppColors.grey,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => onUpdateStatus(LabStatus.outLab),
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('나가기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isInLab ? AppColors.primary : AppColors.lightGrey,
              foregroundColor: isInLab ? Colors.white : AppColors.grey,
            ),
          ),
        ),
      ],
    );
  }
}