import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';

/// 출석 현황 카드 - 월별 출석 그리드, 출석 빈도 범례, 이번 달 요약
class AttendanceStatusCard extends StatelessWidget {
  const AttendanceStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFFFFF),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 출석 현황 + 출석 빈도 범례
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '출석 현황',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '출석 빈도',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildLegendBlock(0.2),
                    _buildLegendBlock(0.4),
                    _buildLegendBlock(0.6),
                    _buildLegendBlock(0.8),
                    _buildLegendBlock(1.0),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 월별 출석 그리드
            _buildMonthlyGrid(),
            const SizedBox(height: 16),

            // 이번 달 출석 현황 요약
            const Text(
              '이번 달 출석 현황',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendBlock(double intensity) {
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.only(right: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(intensity),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildMonthlyGrid() {
    // 더미 데이터: 5주차 x 7일, 출석 빈도 0~1
    final attendanceData = _generateDummyAttendance();
    final weekLabels = ['1주차', '2주차', '3주차', '4주차', '5주차'];
    final dayLabels = ['월', '화', '수', '목', '금', '토', '일'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // 9월 + 요일 헤더
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '9월',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    ...weekLabels.map((label) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    // 요일 헤더
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: dayLabels
                          .map((d) => SizedBox(
                                width: 20,
                                child: Text(
                                  d,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 4),
                    // 주차별 출석 블록
                    ...List.generate(5, (weekIndex) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(7, (dayIndex) {
                            final intensity = attendanceData[weekIndex][dayIndex];
                            return Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: intensity > 0
                                    ? AppColors.primary.withOpacity(0.2 + intensity * 0.8)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              // 주차별 총 시간
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(5, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      '··· ${72 + i * 8}시간',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<List<double>> _generateDummyAttendance() {
    // 5주 x 7일, 0~1 사이 값 (출석 빈도)
    return List.generate(5, (week) {
      return List.generate(7, (day) {
        if (week == 4 && day > 2) return 0.0; // 5주차는 일부만
        return (week * 7 + day) % 10 / 10.0; // 다양한 빈도
      });
    });
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryBox('18일', '총 출석일'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryBox('5일', '연속 출석'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryBox('78%', '출석률', highlight: true),
        ),
      ],
    );
  }

  Widget _buildSummaryBox(String value, String label, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: highlight ? AppColors.primary : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
