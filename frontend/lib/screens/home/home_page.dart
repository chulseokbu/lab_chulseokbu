import 'dart:async';
// 💡 [삭제] import 'package:intl/intl.dart'; -> 사용하지 않음
import 'package:flutter/material.dart';
// 💡 [삭제] import 'package:http/http.dart' as http; -> LabStayService가 대신 처리함
// 💡 [삭제] import 'dart:convert'; -> HomePage에서 직접 파싱할 일이 없어짐
import 'package:frontend/HomeTab/Views/AttendanceStatusCard.dart';
import 'package:frontend/HomeTab/Views/EditProfileView.dart';
import 'package:frontend/HomeTab/Views/NotificationView.dart';
import 'package:frontend/Group_Tab/MeetingListScreen.dart';
import 'package:frontend/HomeTab/Views/RetentionStatusView.dart';
import 'package:frontend/TabBar/Shared_widgets.dart';
import 'package:frontend/HomeTab/Views/Profile_Service.dart';
import 'package:frontend/HomeTab/Views/InOutStateView.dart';
import 'package:frontend/core/theme/app_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.onLogout});
  final VoidCallback? onLogout;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final ProfileService _profileService = ProfileService();
  final GlobalKey<LabStatusCardState> _labStatusKey = GlobalKey();
  final GlobalKey<AttendanceStatusCardState> _attendanceKey = GlobalKey<AttendanceStatusCardState>();

  String _currentName = '로딩 중...';
  String _currentStudentId = '';
  String _currentPhone = '';
  String _currentEmail = '';

  // 💡 [삭제] _monthlyStayData 변수 -> AttendanceStatusCard가 내부에서 직접 관리함
  DateTime? _currentCheckInTime;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final data = await _profileService.loadProfile();
      if (mounted) {
        setState(() {
          _currentName = data['name'] ?? '미설정';
          _currentStudentId = data['studentId'] ?? '';
          _currentPhone = data['phone'] ?? '';
          _currentEmail = data['email'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("❌ 유저 정보 로드 실패: $e");
    }
  }

  // 💡 [삭제] _fetchMonthlyStayData() 함수
  // -> 출석 데이터는 _attendanceKey.currentState?.fetchMonthlyAttendance()를 통해
  //    AttendanceStatusCard 위젯이 직접 최신화하므로 여기서 중복으로 가져올 필요가 없습니다.

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return SingleChildScrollView(
          child: Container(
            color: AppColors.background,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LabStatusCard(
                  key: _labStatusKey,
                  onStatusUpdated: (DateTime? time) {
                    setState(() {
                      _currentCheckInTime = time;
                    });
                    // 💡 체크인/체크아웃 상태가 바뀌면 출석 카드를 새로고침하라고 명령함
                    _attendanceKey.currentState?.fetchMonthlyAttendance();
                  },
                ),
                const SizedBox(height: 16),
                AttendanceStatusCard(key: _attendanceKey),
                const SizedBox(height: 16),
                NotificationView(
                  embedded: true,
                  checkInTime: _currentCheckInTime,
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      case 1: return const MeetingListScreen();
      case 2: return const RetentionStatusView();
      default: return const Center(child: Text('페이지 없음'));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold 및 AppBar 부분은 이전과 동일 (생략)
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text(_selectedIndex == 0 ? '출석뷰' : '랩실 출석부',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => _showEditProfileDialog(),
            child: Row(
              children: [
                Text(_currentName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Text(_currentName.isNotEmpty ? _currentName[0] : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
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
          await _profileService.saveProfile(
            name: name,
            studentId: id,
            memberId: int.tryParse(id),
            phone: phone,
            email: email,
          );
          await _loadUserData();
        },
        onLogout: () async {
          await _labStatusKey.currentState?.autoCheckOut();
          widget.onLogout?.call();
        },
      ),
    );
  }
}