import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/HomeTab/Views/AttendanceStatusCard.dart';
import 'package:frontend/HomeTab/Views/EditProfileView.dart';
import 'package:frontend/HomeTab/Views/InOutStateView.dart';
import 'package:frontend/HomeTab/Views/NotificationView.dart';
import 'package:frontend/Group_Tab/MeetingListScreen.dart';
import 'package:frontend/HomeTab/Views/RetentionStatusView.dart';
import 'package:frontend/TabBar/Shared_widgets.dart';

/// 메인 홈 화면 (탭 네비게이션)
class HomePage extends StatefulWidget {
  const HomePage({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  String _currentName = '김학생';
  String _currentStudentId = '20230123';
  String _currentPhone = '010-1234-5678';
  String _currentEmail = 'student@university.ac.kr';

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => EditProfileDialog(
        initialName: _currentName,
        initialStudentId: _currentStudentId,
        initialPhone: _currentPhone,
        initialEmail: _currentEmail,
        onSave: (newName, newId, newPhone, newEmail) async {
          if (mounted) {
            setState(() {
              _currentName = newName;
              _currentStudentId = newId;
              _currentPhone = newPhone;
              _currentEmail = newEmail;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('프로필이 저장되었습니다.'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        onLogout: widget.onLogout,
      ),
    );
  }

  static final List<Widget> _tabContents = [
    SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          LabStatusCard(),
          SizedBox(height: 16),
          AttendanceStatusCard(),
          SizedBox(height: 16),
          NotificationView(embedded: true),
          SizedBox(height: 100),
        ],
      ),
    ),
    const MeetingListScreen(),
    const RetentionStatusView(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentTitle =
        _selectedIndex == 0 ? '출석뷰' : (_selectedIndex == 1 ? '출석뷰' : '랩실 출석부');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              currentTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: _showEditProfileDialog,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentName,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          _currentName.isNotEmpty ? _currentName[0] : '?',
                          style: const TextStyle(
                            color: AppColors.surface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_selectedIndex == 2)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.background,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _tabContents.elementAt(_selectedIndex),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onItemSelected: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}
