import 'package:flutter/material.dart';
import 'package:frontend/core/stay_heatmap.dart';
import 'package:frontend/services/lab_stay_service.dart';
import 'package:frontend/models/lab_stay_models.dart';

class AttendanceStatusCard extends StatefulWidget {
  const AttendanceStatusCard({super.key});

  @override
  State<AttendanceStatusCard> createState() => AttendanceStatusCardState();
}

class AttendanceStatusCardState extends State<AttendanceStatusCard> {
  Map<String, String> _stayDurationMap = {};
  bool _isLoading = true;
  final DateTime _now = DateTime.now();

  // 계산된 통계 데이터
  int _totalAttendanceDays = 0;
  int _consecutiveDays = 0;
  double _attendanceRate = 0.0;
  Map<int, int> _weeklyTotalMinutes = {};

  @override
  void initState() {
    super.initState();
    fetchMonthlyAttendance();
  }

  // 데이터 로드 및 통계 계산 함수
  Future<void> fetchMonthlyAttendance() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 💡 LabStayService를 통해 실제 30일 데이터를 가져옴
      final List<DailyStayRecord> records = await LabStayService.instance.getLast30Days();
      final Map<String, String> tempMap = {};

      for (var record in records) {
        if (record.date != null) {
          // 서버 날짜 형식을 'yyyy-MM-dd'로 통일
          String dateKey = record.date!.split('T')[0].split(' ')[0];
          tempMap[dateKey] = record.duration ?? "0분";
        }
      }

      if (mounted) {
        setState(() {
          _stayDurationMap = tempMap;
          _calculateRealStatistics(); // 실제 수치 계산
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("데이터 로드 중 오류 발생: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 실제 데이터를 기반으로 통계 수치 계산
  void _calculateRealStatistics() {
    int totalDaysInMonth = DateTime(_now.year, _now.month + 1, 0).day;
    int attendedCount = 0;
    int maxConsecutive = 0;
    int currentConsecutive = 0;
    Map<int, int> weeklyMins = {};

    final firstDayOfMonth = DateTime(_now.year, _now.month, 1);
    final int firstWeekday = firstDayOfMonth.weekday;

    for (int day = 1; day <= totalDaysInMonth; day++) {
      String dateKey = "${_now.year}-${_now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
      String? duration = _stayDurationMap[dateKey];

      final minutes = StayHeatmap.parseDurationToMinutes(duration);
      final isAttended = minutes > 0;

      if (isAttended) {
        attendedCount++;
        currentConsecutive++;
        if (currentConsecutive > maxConsecutive) maxConsecutive = currentConsecutive;
        int weekIdx = (day + firstWeekday - 2) ~/ 7;
        weeklyMins[weekIdx] = (weeklyMins[weekIdx] ?? 0) + minutes;
      } else {
        currentConsecutive = 0;
      }
    }

    _totalAttendanceDays = attendedCount;
    _consecutiveDays = maxConsecutive;
    _attendanceRate = (totalDaysInMonth > 0) ? (attendedCount / totalDaysInMonth) * 100 : 0;
    _weeklyTotalMinutes = weeklyMins;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMainCard(),
        const SizedBox(height: 12),
        _buildStatisticsCards(),
      ],
    );
  }

  Widget _buildMainCard() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_now.month}월 출석 현황', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                _buildLegend(),
              ],
            ),
            const SizedBox(height: 20),
            _buildCalendarGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        const Text('빈도 ', style: TextStyle(fontSize: 10, color: Colors.grey)),
        ...StayHeatmap.legendColors.map(_legendBox),
      ],
    );
  }

  Widget _legendBox(Color color) => Container(width: 8, height: 8, margin: const EdgeInsets.only(left: 2), color: color);

  Widget _buildCalendarGrid() {
    final List<String> weekDays = ['월', '화', '수', '목', '금', '토', '일'];
    final firstDayOfMonth = DateTime(_now.year, _now.month, 1);
    final int firstWeekday = firstDayOfMonth.weekday;

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 45),
            ...weekDays.map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(fontSize: 11, color: Colors.grey))))),
            const SizedBox(width: 40),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(5, (weekIdx) => _buildWeekRow(weekIdx, firstWeekday)),
      ],
    );
  }

  Widget _buildWeekRow(int weekIdx, int firstWeekday) {
    int weekMins = _weeklyTotalMinutes[weekIdx] ?? 0;
    String weekTimeStr = weekMins > 0
        ? (weekMins >= 60 ? "${(weekMins / 60).toStringAsFixed(1)}h" : "${weekMins}m")
        : "";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 45, child: Text('${weekIdx + 1}주차', style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w500))),
          ...List.generate(7, (dayIdx) {
            int dayNumber = (weekIdx * 7) + (dayIdx + 1) - (firstWeekday - 1);
            int totalDaysInMonth = DateTime(_now.year, _now.month + 1, 0).day;
            bool isDateInMonth = dayNumber > 0 && dayNumber <= totalDaysInMonth;
            String dateKey = "${_now.year}-${_now.month.toString().padLeft(2, '0')}-${dayNumber.toString().padLeft(2, '0')}";

            return Expanded(
              child: AspectRatio(
                aspectRatio: 1.2,
                child: Container(
                  margin: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: isDateInMonth
                        ? StayHeatmap.colorForDurationString(_stayDurationMap[dateKey])
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            );
          }),
          SizedBox(width: 40, child: Text(weekTimeStr, textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Row(
      children: [
        _statBox('$_totalAttendanceDays일', '총 출석일'),
        const SizedBox(width: 8),
        _statBox('$_consecutiveDays일', '연속 출석'),
        const SizedBox(width: 8),
        _statBox('${_attendanceRate.toStringAsFixed(0)}%', '출석률', isHighlight: true),
      ],
    );
  }

  Widget _statBox(String value, String label, {bool isHighlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isHighlight ? Colors.orange : Colors.black)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}