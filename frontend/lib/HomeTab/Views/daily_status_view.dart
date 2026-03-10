import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/models/attendance_record.dart';

class DailyStatusView extends StatefulWidget {
  const DailyStatusView({super.key});

  @override
  State<DailyStatusView> createState() => _DailyStatusViewState();
}

class _DailyStatusViewState extends State<DailyStatusView> {
  bool _isListView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildAttendanceFrequencySection(),
              const SizedBox(height: 16),
              Expanded(
                child: _buildContentArea(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            const Text(
              '랩실 구성원 출석 현황',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        _buildToggleButtons(),
      ],
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFECECEC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildToggleButton(Icons.grid_view_rounded, !_isListView),
          _buildToggleButton(Icons.format_list_bulleted_rounded, _isListView),
        ],
      ),
    );
  }

  Widget _buildToggleButton(IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isListView = (icon == Icons.format_list_bulleted_rounded);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.black87 : Colors.grey[600],
          size: 20,
        ),
      ),
    );
  }

  Widget _buildAttendanceFrequencySection() {
    return Row(
      children: [
        Text('출석 빈도:', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        const SizedBox(width: 8),
        for (double i = 0.2; i <= 1.0; i += 0.2)
          Container(
            width: 14, height: 14,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(i),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }

  Widget _buildContentArea() {
    // 💡 현재는 빈 리스트 (서버 데이터 연동 전)
    final List<Map<String, dynamic>> members = [];

    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('아직 출석한 구성원이 없습니다.',
                style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return _isListView ? _buildListView(members) : _buildGridView(members);
  }

  // 💡 오류 해결: 누락된 리스트 뷰 빌더 추가
  Widget _buildListView(List<Map<String, dynamic>> members) {
    return ListView.builder(
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return MemberAttendanceCard(
          name: member['name'] ?? '',
          role: member['role'] ?? '',
          percentage: member['percentage'] ?? '0%',
          initial: member['initial'] ?? '',
          color: member['color'] ?? AppColors.primary,
          allRecords: List<AttendanceRecord>.from(member['records'] ?? []),
        );
      },
    );
  }

  // 💡 오류 해결: 누락된 그리드 뷰 빌더 추가
  Widget _buildGridView(List<Map<String, dynamic>> members) {
    return const Center(child: Text('그리드 뷰를 준비 중입니다.'));
  }
}

class MemberAttendanceCard extends StatelessWidget {
  final String name;
  final String role;
  final String percentage;
  final String initial;
  final Color color;
  final List<AttendanceRecord> allRecords;

  const MemberAttendanceCard({
    super.key,
    required this.name,
    required this.role,
    required this.percentage,
    required this.initial,
    required this.color,
    required this.allRecords,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Text(initial, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(role, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            const Spacer(),
            Text(percentage, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        children: const [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("상세 기록이 없습니다."),
          )
        ],
      ),
    );
  }
}