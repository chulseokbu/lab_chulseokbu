import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_colors.dart';

class AlarmData {
  final String title;
  final String time;
  final bool isCompleted;

  AlarmData({required this.title, required this.time, required this.isCompleted});
}

class NotificationView extends StatefulWidget {
  final bool embedded;
  final DateTime? checkInTime;

  const NotificationView({super.key, this.embedded = false, this.checkInTime});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  List<AlarmData> _generatedAlarms = [];

  @override
  void initState() {
    super.initState();
    _generateAlarmsFromCheckIn();
  }

  @override
  void didUpdateWidget(covariant NotificationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.checkInTime != oldWidget.checkInTime) {
      _generateAlarmsFromCheckIn();
    }
  }

  // 💡 알람 생성 로직 수정: 2시간 간격, 3차까지
  void _generateAlarmsFromCheckIn() {
    if (widget.checkInTime == null) {
      setState(() => _generatedAlarms = []);
      return;
    }

    List<AlarmData> tempAlarms = [];
    DateTime now = DateTime.now();

    // 💡 i <= 3 (3차까지), Duration(hours: 2 * i) (2시간 간격)
    for (int i = 1; i <= 3; i++) {
      DateTime alarmTime = widget.checkInTime!.add(Duration(hours: 2 * i));
      tempAlarms.add(AlarmData(
        title: '$i차 잔류 확인 알림',
        time: DateFormat('HH:mm').format(alarmTime),
        isCompleted: now.isAfter(alarmTime),
      ));
    }
    setState(() => _generatedAlarms = tempAlarms);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('진행 중인 체크인 알림',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              if (widget.checkInTime != null)
                Text(
                  '2시간 간격 / 총 3회',
                  style: TextStyle(fontSize: 11, color: AppColors.primary.withOpacity(0.8)),
                ),
            ],
          ),
        ),
        if (_generatedAlarms.isEmpty)
          _buildEmptyState()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _generatedAlarms.length,
            itemBuilder: (context, index) => _buildAlarmCard(_generatedAlarms[index]),
          ),
      ],
    );
  }

  Widget _buildAlarmCard(AlarmData alarm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2)
          )
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: alarm.isCompleted ? Colors.green : Colors.orangeAccent,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12)
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                        alarm.isCompleted ? Icons.check_circle : Icons.access_time_filled,
                        color: alarm.isCompleted ? Colors.green : Colors.orangeAccent,
                        size: 20
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              alarm.title,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: alarm.isCompleted ? AppColors.grey : AppColors.textPrimary,
                                  decoration: alarm.isCompleted ? TextDecoration.lineThrough : null
                              )
                          ),
                          Text(
                            alarm.isCompleted ? '확인 완료' : '예정 시각: ${alarm.time}',
                            style: const TextStyle(fontSize: 11, color: AppColors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (!alarm.isCompleted)
                      Text(
                          alarm.time,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.dividerGrey.withOpacity(0.5))
      ),
      child: const Column(
        children: [
          Icon(Icons.notifications_none_rounded, color: AppColors.lightGrey, size: 32),
          SizedBox(height: 8),
          Text('진행 중인 체크인이 없습니다.', style: TextStyle(color: AppColors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}