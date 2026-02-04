// auth_screens.dart 파일 내용

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
// 이미지에서 볼 수 있는 주황색 버튼 색상
const Color _orangeColor = Color(0xFFE68840);
const Color _hintTextColor = Color(0xFFCCCCCC);
const Color _backgroundColor = Color(0xFFFFFFFF);
const Color _lightOrangeBackground = Color(0xFFFFF7F0);
// --- 1. 로그인 화면 ---
class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    required this.onGoToSignUp,
  });

  final VoidCallback onLoginSuccess;
  final VoidCallback onGoToSignUp;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 💡 수정 1: 전체 Scaffold의 배경색을 연한 주황색 계열로 변경
      backgroundColor: _lightOrangeBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0), // 좌우 패딩 조정
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // 로고 및 제목
              const Icon(Icons.menu_book, size: 60, color: _orangeColor),
              const SizedBox(height: 8),
              const Text(
                '랩실 출석부',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text(
                '로그인하여 시작하세요',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54), // 색상 조정
              ),
              const SizedBox(height: 40),

              // 💡 수정 2: 로그인 폼 부분을 흰색 Card로 감싸서 이미지를 재현
              Card(
                color: _backgroundColor, // 카드 배경색을 흰색으로 지정
                elevation: 4, // 그림자 효과
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // 이메일 입력 필드
                      const Text('이메일', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const TextField(
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'example@university.ac.kr',
                          hintStyle: TextStyle(color: _hintTextColor),
                          filled: true,
                          fillColor: Colors.white, // 배경색이 흰색일 때 대비를 위해 유지
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(
                            color: Colors.grey, // 이미지와 유사한 연한 회색 테두리
                              width: 1.0,),

                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 비밀번호 입력 필드
                      const Text('비밀번호', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const TextField(
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: '비밀번호를 입력하세요',
                          hintStyle: TextStyle(color: _hintTextColor),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(
                              color: Colors.grey, // 이미지와 유사한 연한 회색 테두리
                              width: 1.0,),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 로그인 버튼
                      ElevatedButton(
                        onPressed: onLoginSuccess,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orangeColor,
                          foregroundColor: _backgroundColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('로그인', style: TextStyle(fontSize: 18)),
                      ),

                      const SizedBox(height: 16),

                      // 계정이 없으신가요? 회원가입
                      Center(
                        child: Text.rich(
                          TextSpan(
                            text: '계정이 없으신가요? ',
                            style: const TextStyle(color: Colors.black54),
                            children: <TextSpan>[
                              TextSpan(
                                text: '회원가입',
                                style: const TextStyle(
                                  color: _orangeColor,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline, // 옵션: 밑줄 추가
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = onGoToSignUp,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 2. 회원가입 화면 ---
class SignUpScreen extends StatefulWidget { // 💡 StatefulWidget으로 변경
  const SignUpScreen({super.key, required this.onGoToLogin});

  final VoidCallback onGoToLogin;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // 💡 1. TextEditingController: 각 입력 필드의 값을 제어
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // 💡 2. 유효성 검사 상태 변수 (기본값: true. 즉, 오류가 없다는 상태)
  bool _isNameValid = true;
  bool _isStudentIdValid = true;
  bool _isPhoneValid = true;
  bool _isEmailValid = true;

  // 💡 3. 유효성 검사 로직
  void _validateAndSubmit() {
    setState(() {
      // 모든 필드의 현재 유효성 검사 실행
      _isNameValid = _nameController.text.isNotEmpty;
      // 학번은 8자리 이상인지 추가 검사 (이미지 '8-10자리 숫자' 참고)
      _isStudentIdValid = _studentIdController.text.length >= 8;
      _isPhoneValid = _phoneController.text.isNotEmpty;
      _isEmailValid = _emailController.text.isNotEmpty;
    });

    // 모든 필드가 유효하면 로그인 화면으로 돌아갑니다. (실제로는 서버 가입 로직 수행)
    if (_isNameValid && _isStudentIdValid && _isPhoneValid && _isEmailValid) {
      widget.onGoToLogin();
    }
  }

  @override
  void dispose() {
    // Controller 사용 후 반드시 dispose
    _nameController.dispose();
    _studentIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... (build 메서드 내용: 이 부분은 이전 코드와 동일합니다)
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onGoToLogin,
          color: Colors.black,
        ),
        title: const Text('회원가입', style: TextStyle(color: Colors.black)),
        backgroundColor: _lightOrangeBackground,
      ),
      backgroundColor: _lightOrangeBackground, // 수정: 배경색 _backgroundColor -> _lightOrangeBackground
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ... (앱 로고 및 제목)
            const Icon(Icons.menu_book, size: 60, color: _orangeColor),
            const SizedBox(height: 16),
            const Text(
              '회원가입',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              '정보를 입력하여 가입하세요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // 입력 폼을 흰색 카드로 감싸서 이미지 디자인 재현
            Card(
              color: _backgroundColor,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 이름 입력 필드
                    _buildInputField(
                      controller: _nameController,
                      label: '이름',
                      hintText: '홍길동',
                      isValid: _isNameValid,
                      errorMessage: '이름을 입력해주세요',
                    ),

                    // 학번 입력 필드
                    _buildInputField(
                      controller: _studentIdController,
                      label: '학번',
                      hintText: '20241234',
                      keyboardType: TextInputType.number,
                      helperText: '8-10자리 숫자',
                      isValid: _isStudentIdValid,
                      errorMessage: '학번을 8자리 이상 입력해주세요',
                    ),

                    // 전화번호 입력 필드
                    _buildInputField(
                      controller: _phoneController,
                      label: '전화번호',
                      hintText: '010-1234-5678',
                      keyboardType: TextInputType.phone,
                      isValid: _isPhoneValid,
                      errorMessage: '전화번호를 입력해주세요',
                    ),

                    // 이메일 입력 필드
                    _buildInputField(
                      controller: _emailController,
                      label: '이메일',
                      hintText: 'example@university.ac.kr',
                      keyboardType: TextInputType.emailAddress,
                      isValid: _isEmailValid,
                      errorMessage: '이메일을 입력해주세요',
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // 가입하기 버튼
            ElevatedButton(
              onPressed: _validateAndSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _orangeColor,
                foregroundColor: _backgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('가입하기', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  // 💡 4. 공통 입력 필드 위젯 (이 메서드를 클래스 내부에 정의해야 합니다!)
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required bool isValid,
    required String errorMessage,
    TextInputType keyboardType = TextInputType.text,
    String? helperText,
    bool obscureText = false,
  }) {
    const Color _orangeColor = Color(0xFFE68840); // _buildInputField 내에서도 사용하기 위해 재정의 혹은 상단 const 사용

    // 오류가 있을 경우 빨간색 테두리
    final borderColor = isValid ? Colors.grey : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0), // 필드 간 간격
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (helperText != null)
            Text(helperText, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: _hintTextColor),
              filled: true,
              fillColor: Colors.white,
              // 💡 테두리 색상을 isValid 상태에 따라 변경
              border: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(
                  color: borderColor,
                  width: 1.0,
                ),
              ),
              // 💡 포커스 시 테두리 색상도 변경 (에러 상태가 아닐 경우 주황색 유지)
              focusedBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(
                  color: isValid ? _orangeColor : Colors.red,
                  width: 1.0,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            // 입력할 때마다 유효성 상태를 리셋하여 경고를 숨기기 위해 리스너 추가 (옵션)
            onChanged: (text) {
              if (!isValid) {
                setState(() {
                  // 사용자가 입력 시작하면 오류 표시를 숨김
                  if (label == '이름') _isNameValid = true;
                  if (label == '학번') _isStudentIdValid = true;
                  if (label == '전화번호') _isPhoneValid = true;
                  if (label == '이메일') _isEmailValid = true;
                });
              }
            },
          ),
          // 💡 유효성 검사 실패 시 경고 메시지 출력
          if (!isValid)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}