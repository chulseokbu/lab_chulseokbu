// lib/attendance_view.dart
import 'package:flutter/material.dart';

// =======================================================
// 출석뷰 메인 화면 위젯
// =======================================================
class AttendanceViewScreenContent extends StatelessWidget {
  const AttendanceViewScreenContent({super.key});

  // private 헬퍼 함수들은 이 파일 안에 두어도 됩니다.
  Widget _buildColorIndicator(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 30,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Scaffold, AppBar 없이 내용만 반환
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ⭐ 1. 기존 AppBar에서 가져온 '김학생' 프로필 정보를 재구성
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0), // 하단 간격 추가
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end, // 오른쪽 끝으로 정렬
              children: [
                const Text('김학생', style: TextStyle(color: Colors.black)),
                const SizedBox(width: 4),
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.deepOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '김',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // ⭐ 2. '랩실 구성원 출석 현황' 타이틀
          const Text(
            '랩실 구성원 출석 현황',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          // 3. 출석 빈도 (Colors.deepOrange를 bgc로 바꿀 수 있지만 기존 색상 유지)
          Row(
            children: [
              const Text('출석 빈도:', style: TextStyle(color: Colors.grey)),
              const SizedBox(width: 8),
              _buildColorIndicator(Colors.amber.shade100),
              _buildColorIndicator(Colors.amber.shade200),
              _buildColorIndicator(Colors.amber.shade400),
              _buildColorIndicator(Colors.deepOrange.shade400),
            ],
          ),

          const SizedBox(height: 20),

          // 4. AttendanceTile 목록
          const AttendanceTile(
            name: '김학생',
            major: '박사과정',
            initials: '김',
            color: Colors.deepOrange,
            attendanceRate: 85,
            initiallyExpanded: true,
          ),
          const SizedBox(height: 16),
          // ... (나머지 AttendanceTile 목록) ...
        ],
      ),
    );
  }
}

// =======================================================
// 확장 가능한 출석 항목 위젯 (Customized ExpansionTile)
// =======================================================
class AttendanceTile extends StatelessWidget {
  final String name;
  final String major;
  final String initials;
  final Color color;
  final int attendanceRate;
  final bool initiallyExpanded;

  const AttendanceTile({
    super.key,
    required this.name,
    required this.major,
    required this.initials,
    required this.color,
    required this.attendanceRate,
    this.initiallyExpanded = false,
  });

  Widget _buildCustomTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  major,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                '$attendanceRate %',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Text(
                '출석률',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildExpandedChildren() {
    return <Widget>[
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 20.0, vertical: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      margin: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          listTileTheme: const ListTileThemeData(
            contentPadding: EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          controlAffinity: ListTileControlAffinity.trailing,
          iconColor: Colors.grey,
          collapsedIconColor: Colors.grey,
          title: _buildCustomTitle(context),
          children: _buildExpandedChildren(),
        ),
      ),
    );
  }
}