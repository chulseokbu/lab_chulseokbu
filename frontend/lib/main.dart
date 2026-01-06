import 'package:flutter/material.dart';
import 'package:frontend/HomeTab/Views/InOutStateView.dart';
import 'package:frontend/MemberTab/MemberStateView.dart';
import 'package:frontend/TabBar/Shared_widgets.dart';
import 'package:frontend/HomeTab/Views/NotificationView.dart';
import 'package:frontend/HomeTab/Views/daily_status_view.dart';
import 'package:frontend/HomeTab/Views/EditProfileView.dart';
import 'package:frontend/HomeTab/AuthTab/AuthScreen.dart';
void main() {
  runApp(const MyApp());
}

const BGC = Color(0xFFFFFFFF);


class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}


class _AuthGateState extends State<AuthGate> {
  // 💡 핵심: 로그인 상태를 관리하는 변수 (기본값: false)
  bool _isLoggedIn = false;
  // 💡 회원가입/로그인 화면 전환을 위한 변수 (기본값: false)
  bool _isSigningUp = false;

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
    if (_isLoggedIn) {
      // 🟢 로그인 상태일 경우: 메인 화면 (`MyHomePage`) 표시
      return const MyHomePage(title: '랩실 출석부');
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
        colorScheme: ColorScheme.fromSeed(seedColor: BGC),
      ),
      home: const AuthGate(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

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

          // 2. 출석 현황 위젯 자리
          SizedBox(
            height: 150,
            child: Center(
              child: Text(
                '출석 현황 위젯 자리',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          ),

          SizedBox(height: 16), // 위젯 간 간격

          // 3. NotificationView (알림 목록)
          // ListView 안에 ListView가 중첩되는 문제를 피하기 위해,
          // NotificationView에 높이를 제한했던 것처럼 여기서도 제한된 높이를 유지합니다.
          // 전체가 SingleChildScrollView 안에 있으므로, 이 위젯의 높이가 300을 초과하면
          // 바깥쪽 SingleChildScrollView가 스크롤됩니다.
          SizedBox(
            height: 600,
            child: NotificationView(),
          ),

          SizedBox(height: 20),
          // 만약 여기에 더 많은 내용이 있다면, 스크롤 가능합니다.
          Center(child: Text('스크롤 확인용 추가 내용', style: TextStyle(fontSize: 14, color: Colors.blueGrey))),
          SizedBox(height: 100), // 스크롤 테스트를 위한 여백
        ],
      ),
    ),

    // [1] 구성원 화면
    // AttendanceViewScreenContent가 이미 스크롤 가능한 구조라면 그대로 둡니다.
    const DailyStatusView(),

    // [2] 잔류현황 화면 (임시 위젯)
    const Center(
      child: Text('잔류 현황 페이지', style: TextStyle(fontSize: 20)),
    ),
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
    String currentTitle = widget.title;
    if (_selectedIndex == 1) {
      currentTitle = '출석뷰'; // 구성원 탭을 눌렀을 때 타이틀 변경
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: BGC,
        title: Text(currentTitle),
        actions: <Widget>[
          GestureDetector(
            onTap: _showEditProfileDialog,

            // 4번째 사진(프로필 아이콘)과 유사한 형태의 위젯을 구성합니다.
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // '김학생' 텍스트 (옵션, '출석뷰' 화면에선 보임)
                  if (_selectedIndex == 1) // 구성원 탭일 때만 텍스트를 보여준다고 가정
                    const Text(
                      '김학생',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  const SizedBox(width: 8), // 텍스트와 아이콘 간 간격
                  // 원형 프로필 아이콘 ('김')
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFE68840), // 오렌지색 계열 (이미지 참고)
                    child: Text(
                      '김',
                      style: TextStyle(color: BGC, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        // 필요하다면 앱바의 Actions(오른쪽 상단)도 여기에 배치할 수 있습니다.
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