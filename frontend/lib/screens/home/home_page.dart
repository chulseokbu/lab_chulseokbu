import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/api/api_config.dart';
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
import 'package:frontend/core/widgets/app_logo.dart';

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

  Future<void> _refreshHomeTab() async {
    await _labStatusKey.currentState?.refreshFromServer();
    if (!mounted) return;
    setState(() {
      _currentCheckInTime =
          _labStatusKey.currentState?.checkInTimeForNotification;
    });
    await _attendanceKey.currentState?.fetchMonthlyAttendance();
    await _loadUserData();
  }

  List<Widget> _buildTabContents() {
    return [
      RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refreshHomeTab,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                    void refreshAttendance() {
                      _attendanceKey.currentState?.fetchMonthlyAttendance();
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      refreshAttendance();
                      Future<void>.delayed(
                        const Duration(milliseconds: 400),
                        refreshAttendance,
                      );
                    });
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
        ),
      ),
      const MeetingListScreen(),
      const RetentionStatusView(),
    ];
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
        title: Semantics(
          label: '출석뷰',
          child: const AppLogoImage(size: 40, borderRadius: 11),
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
      body: IndexedStack(
        index: _selectedIndex,
        children: _buildTabContents(),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onItemSelected: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }

  void _showEditProfileDialog() {
    showDialog<bool>(
      context: context,
      builder: (context) => EditProfileDialog(
        initialNickname: _currentName,
        initialStudentId: _currentStudentId,
        initialPhone: _currentPhone,
        initialEmail: _currentEmail,
        onSave: (nickname, id) async {
          await _profileService.saveProfile(
            name: nickname,
            studentId: id,
            memberId: int.tryParse(id),
            phone: _currentPhone,
            email: _currentEmail,
          );
          await _loadUserData();
        },
        onWithdrawAccount: () async {
          final data = await _profileService.loadProfile();
          final token = data['accessToken'];
          if (token == null || token.isEmpty) {
            return '로그인이 필요합니다.';
          }
          try {
            final response = await http.delete(
              Uri.parse('${ApiConfig.baseUrl}${ApiConfig.withdrawAccount}'),
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            );
            if (response.statusCode == 200) {
              return null;
            }
            var msg = '';
            try {
              final decoded = json.decode(utf8.decode(response.bodyBytes));
              if (decoded is Map<String, dynamic>) {
                msg = (decoded['message'] ?? '').toString();
              }
            } catch (_) {
              msg = utf8.decode(response.bodyBytes);
            }
            if (response.statusCode == 401) {
              return msg.isNotEmpty ? msg : '인증이 만료되었습니다. 다시 로그인해주세요.';
            }
            return msg.isNotEmpty ? msg : '탈퇴 처리에 실패했습니다.';
          } catch (e) {
            debugPrint('탈퇴 요청 오류: $e');
            return '네트워크 오류로 탈퇴에 실패했습니다.';
          }
        },
        onLogout: () async {
          await _labStatusKey.currentState?.autoCheckOut();
          widget.onLogout?.call();
        },
      ),
    ).then((withdrawn) {
      // 다이얼로그 라우트가 완전히 정리된 뒤 한 프레임에 탈퇴 후처리 (빌드 스코프·_dependents 충돌 방지)
      if (withdrawn != true) return;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _labStatusKey.currentState?.autoCheckOut();
        if (!mounted) return;
        await _profileService.clearProfile();
        if (!mounted) return;
        widget.onLogout?.call();
      });
    });
  }
}