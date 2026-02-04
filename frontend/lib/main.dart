import 'package:flutter/material.dart';
import 'package:frontend/HomeTab/Views/InOutStateView.dart';
import 'package:frontend/TabBar/Shared_widgets.dart';
import 'package:frontend/HomeTab/Views/NotificationView.dart';
import 'package:frontend/HomeTab/Views/EditProfileView.dart';
import 'package:frontend/HomeTab/AuthTab/AuthScreen.dart';
import 'package:frontend/HomeTab/Views/AttendanceStatusCard.dart';
import 'package:frontend/HomeTab/Views/RetentionStatusView.dart';
import 'package:frontend/Group_Tab/MeetingListScreen.dart';
import 'package:frontend/services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

const BGC = Color(0xFFFFFFFF);
const Color mainOrange = Color(0xFFF97316); // 메인 컬러
const Color backgroundColor = Color(0xFFF9FAFB); // 화면 배경색


class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}


class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true; // 세션 복원 대기
  bool _isLoggedIn = false;
  bool _isSigningUp = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final restored = await AuthService.instance.restoreSession();
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isLoggedIn = restored;
      });
    }
  }

  void _handleLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  void _handleGoToSignUp() {
    setState(() {
      _isSigningUp = true;
    });
  }

  void _handleGoToLogin() {
    setState(() {
      _isSigningUp = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_isLoggedIn) {
      // 🟢 로그인 상태일 경우: 메인 화면 (`MyHomePage`) 표시
      return MyHomePage(
        title: '랩실 출석부',
        onLogout: () async {
          await AuthService.instance.logout();
          if (mounted) setState(() => _isLoggedIn = false);
        },
      );
    } else {
      // 🔴 로그아웃 상태일 경우
      if (_isSigningUp) {
        // 회원가입 화면 표시 (auth_screens.dart에서 import)
        return SignUpScreen(onGoToLogin: _handleGoToLogin);
      } else {
        // 로그인 화면 표시 (auth_screens.dart에서 import)
        return LoginScreen(
          onLoginSuccess: _handleLoginSuccess,
          onGoToSignUp: _handleGoToSignUp,
        );
      }
    }
  }
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});



  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '랩실 출석부',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: mainOrange, brightness: Brightness.light),
      ),
      home: const AuthGate(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, this.onLogout});

  final String title;
  final VoidCallback? onLogout;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // ⭐ 1. 현재 선택된 탭의 인덱스를 상태로 관리합니다. (홈: 0, 구성원: 1, 잔류현황: 2)
  int _selectedIndex = 0;

  String _currentName = '김학생';
  String _currentStudentId = '20230123';
  String _currentPhone = '010-1234-5678';
  String _currentEmail = 'student@university.ac.kr';

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        // EditProfileDialog 클래스를 사용합니다.
        // EditProfileView.dart 파일이 import 되어 있어야 합니다.
        return EditProfileDialog(
          initialName: _currentName,
          initialStudentId: _currentStudentId,
          initialPhone: _currentPhone,
          initialEmail: _currentEmail,
          onSave: (newName, newId, newPhone, newEmail) async {
            // 저장 로직: 상태 업데이트
            if (mounted) {
              setState(() {
                _currentName = newName;
                _currentStudentId = newId;
                _currentPhone = newPhone;
                _currentEmail = newEmail;
              });
              // 저장 완료 알림
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('프로필이 저장되었습니다.'), duration: Duration(seconds: 2)),
              );
            }
          },
          onLogout: widget.onLogout,
        );
      },
    );
  }

  // ⭐ 2. 탭에 따라 body에 표시할 위젯 목록을 정의합니다.
  static final List<Widget> _widgetOptions = <Widget>[
    SingleChildScrollView( // <--- 홈 탭 전체를 스크롤 가능하게 만듦
      padding: const EdgeInsets.all(16.0),
      child: Column( // <--- Column으로 변경
        crossAxisAlignment: CrossAxisAlignment.stretch, // 너비를 부모만큼 채우도록
        children: const <Widget>[
          // 1. 입/퇴실 상태 카드
          LabStatusCard(),

          SizedBox(height: 16), // 위젯 간 간격

          // 2. 출석 현황 카드
          const AttendanceStatusCard(),

          SizedBox(height: 16), // 위젯 간 간격

          // 3. NotificationView (알림 목록)
          // ListView 안에 ListView가 중첩되는 문제를 피하기 위해,
          // NotificationView에 높이를 제한했던 것처럼 여기서도 제한된 높이를 유지합니다.
          // 전체가 SingleChildScrollView 안에 있으므로, 이 위젯의 높이가 300을 초과하면
          // 바깥쪽 SingleChildScrollView가 스크롤됩니다.
          const NotificationView(embedded: true),

          SizedBox(height: 100),
        ],
      ),
    ),

    // [1] 모임 화면 - 모임 리스트 메인 (리스트 중 클릭 시 DailyStatusView로 이동)
    const MeetingListScreen(),

    // [2] 잔류현황 화면
    const RetentionStatusView(),
  ];
  // ⭐ 3. BottomNavigationBar 탭 클릭 시 인덱스 업데이트 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 이전의 _navigateToMemberStateView 함수는 이제 필요 없습니다.

  @override
  Widget build(BuildContext context) {
    // 현재 선택된 인덱스에 따라 AppBar의 타이틀을 변경할 수 있습니다.
    String currentTitle = _selectedIndex == 0 ? '출석뷰' : (_selectedIndex == 1 ? '출석뷰' : widget.title);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.menu_book_rounded, color: mainOrange, size: 24),
            const SizedBox(width: 8),
            Text(
              currentTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          GestureDetector(
            onTap: _showEditProfileDialog,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentName,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: mainOrange,
                        child: Text(
                          _currentName.isNotEmpty ? _currentName[0] : '?',
                          style: const TextStyle(color: BGC, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (_selectedIndex == 2)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.fromBorderSide(BorderSide(color: Color(0xFFF9FAFB), width: 1.5)),
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

      // ⭐ 4. body에 현재 선택된 인덱스의 위젯을 표시합니다.
      body: _widgetOptions.elementAt(_selectedIndex),

      // ⭐ 5. BottomNavigationBar를 CustomBottomNavBar로 연결
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex, // 현재 인덱스를 BottomBar에 전달
        onItemSelected: _onItemTapped, // 클릭 이벤트를 _onItemTapped에 연결
      ),
    );
  }
}