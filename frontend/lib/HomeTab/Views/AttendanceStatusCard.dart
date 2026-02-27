import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/HomeTab/Views/Profile_Service.dart';

class AttendanceStatusCard extends StatefulWidget {
  const AttendanceStatusCard({super.key});

  // 💡 외부(상위 위젯)에서 이 카드의 데이터를 새로고침하고 싶을 때 참조하기 위함
  @override
  State<AttendanceStatusCard> createState() => AttendanceStatusCardState();
}

// 💡 클래스 이름을 Public(AttendanceStatusCardState)으로 변경하여 외부 접근 허용
class AttendanceStatusCardState extends State<AttendanceStatusCard> {
  bool _isLoading = true;
  List<dynamic> _monthlyData = [];
  int _totalDays = 0;
  int _consecutiveDays = 0;
  double _attendanceRate = 0.0;

  @override
  void initState() {
    super.initState();
    fetchMonthlyAttendance(); // 💡 초기 로드
  }

  // 💡 데이터를 가져오는 함수를 Public으로 변경하여 체크아웃 성공 시 호출 가능하게 함
  Future<void> fetchMonthlyAttendance() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final profileService = ProfileService();
      final profile = await profileService.loadProfile();
      final token = profile['accessToken'];

      var headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      };

      var request = http.Request(
          'GET',
          Uri.parse('https://labchulseokbu-production.up.railway.app/lab/stay/month')
      );
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final decodedData = json.decode(responseBody);

        // 💡 서버 응답의 data 필드가 리스트 형태 (각 객체에 stayTime이 누적되어 있다고 가정)
        final List<dynamic> fetchedData = decodedData['data'] ?? [];

        if (mounted) {
          setState(() {
            _monthlyData = fetchedData;
            _calculateSummary(fetchedData);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("데이터 가져오기 실패: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calculateSummary(List<dynamic> data) {
    if (data.isEmpty) return;

    // 1. 총 출석일: 해당 날짜의 누적 stayTime이 0보다 크면 출석으로 인정
    _totalDays = data.where((day) => (day['stayTime'] ?? 0) > 0).length;

    // 2. 출석률: 데이터에 포함된 전체 일수 대비 출석일
    if (data.isNotEmpty) {
      _attendanceRate = (_totalDays / data.length) * 100;
    }

    // 3. 연속 출석
    int count = 0;
    for (var i = data.length - 1; i >= 0; i--) {
      if ((data[i]['stayTime'] ?? 0) > 0) {
        count++;
      } else if (count > 0) {
        break;
      }
    }
    _consecutiveDays = count;
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
        child: _isLoading
            ? const Center(child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ))
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildMonthlyGrid(),
            const SizedBox(height: 16),
            const Text('이번 달 출석 현황', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildSummaryRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('출석 현황', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Row(
          children: [
            Text('출석 빈도', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(width: 8),
            _buildLegendBlock(0.2),
            _buildLegendBlock(0.4),
            _buildLegendBlock(0.6),
            _buildLegendBlock(0.8),
            _buildLegendBlock(1.0),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendBlock(double intensity) {
    return Container(
      width: 14, height: 14,
      margin: const EdgeInsets.only(right: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(intensity),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildMonthlyGrid() {
    final dayLabels = ['월', '화', '수', '목', '금', '토', '일'];
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${now.month}월', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: dayLabels.map((d) => Text(d, style: TextStyle(fontSize: 11, color: Colors.grey.shade600))).toList(),
                ),
                const SizedBox(height: 8),
                for (int week = 0; week < 5; week++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(7, (day) {
                        int index = week * 7 + day;
                        double intensity = 0.0;

                        if (index < _monthlyData.length) {
                          // 💡 stayTime은 누적 분(minute) 단위로 가정
                          double stayTime = (_monthlyData[index]['stayTime'] ?? 0).toDouble();
                          if (stayTime > 0) {
                            // 8시간(480분)을 꽉 찬 농도(1.0)로 계산
                            intensity = (stayTime / 480).clamp(0.2, 1.0);
                          }
                        }

                        return Container(
                          width: 18, height: 18,
                          decoration: BoxDecoration(
                            color: intensity > 0
                                ? AppColors.primary.withOpacity(intensity)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(child: _buildSummaryBox('${_totalDays}일', '총 출석일')),
        const SizedBox(width: 12),
        Expanded(child: _buildSummaryBox('${_consecutiveDays}일', '연속 출석')),
        const SizedBox(width: 12),
        Expanded(child: _buildSummaryBox('${_attendanceRate.toInt()}%', '출석률', highlight: true)),
      ],
    );
  }

  Widget _buildSummaryBox(String value, String label, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: highlight ? AppColors.primary : Colors.black87)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}