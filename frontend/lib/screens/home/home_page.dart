import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/HomeTab/Views/AttendanceStatusCard.dart';
import 'package:frontend/HomeTab/Views/EditProfileView.dart';
import 'package:frontend/HomeTab/Views/NotificationView.dart';
import 'package:frontend/Group_Tab/MeetingListScreen.dart';
import 'package:frontend/HomeTab/Views/RetentionStatusView.dart';
import 'package:frontend/TabBar/Shared_widgets.dart';
import 'package:frontend/HomeTab/Views/Profile_Service.dart';
import 'package:frontend/HomeTab/Views/InOutStateView.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.onLogout});
  final VoidCallback? onLogout;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final ProfileService _profileService = ProfileService();

  // 💡 AttendanceStatusCard의 상태를 제어하기 위한 GlobalKey 추가
  final GlobalKey<AttendanceStatusCardState> _attendanceKey = GlobalKey();

  String _currentName = '로딩 중...';
  String _currentStudentId = '';
  String _currentPhone = '';
  String _currentEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await _profileService.loadProfile();
    if (mounted) {
      setState(() {
        _currentName = data['name'] ?? '미설정';
        _currentStudentId = data['studentId'] ?? '';
        _currentPhone = data['phone'] ?? '';
        _currentEmail = data['email'] ?? '';
      });
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 💡 LabStatusCard에 콜백 추가: 상태 변경(체크인/아웃) 성공 시 출석 카드 새로고침
              LabStatusCard(
                onStatusUpdated: () {
                  _attendanceKey.currentState?.fetchMonthlyAttendance();
                },
              ),
              const SizedBox(height: 16),
              Text('현재 접속 학번: $_currentStudentId', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              // 💡 GlobalKey 연결
              AttendanceStatusCard(key: _attendanceKey),
              const SizedBox(height: 16),
              const NotificationView(embedded: true),
              const SizedBox(height: 100),
            ],
          ),
        );
      case 1:
        return MeetingListScreen();
      case 2:
        return const RetentionStatusView();
      default:
        return const Center(child: Text('페이지를 찾을 수 없습니다.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? '출석뷰' : '랩실 출석부'),
        actions: [
          GestureDetector(
            onTap: () => _showEditProfileDialog(),
            child: Row(
              children: [
                Text(_currentName),
                const SizedBox(width: 8),
                CircleAvatar(child: Text(_currentName.isNotEmpty ? _currentName[0] : '?')),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onItemSelected: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => EditProfileDialog(
        initialName: _currentName,
        initialStudentId: _currentStudentId,
        initialPhone: _currentPhone,
        initialEmail: _currentEmail,
        onSave: (name, id, phone, email) async {
          await _profileService.saveProfile(name: name, studentId: id, phone: phone, email: email);
          await _loadUserData();
        },
        onLogout: widget.onLogout,
      ),
    );
  }
}