import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/HomeTab/Views/Profile_Service.dart';

// --- 1. 로그인 화면 ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLoginSuccess, required this.onGoToSignUp});
  final VoidCallback onLoginSuccess;
  final VoidCallback onGoToSignUp;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    try {
      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      };

      var request = http.Request(
        'POST',
        Uri.parse('https://labchulseokbu-production.up.railway.app/lab/users/login'),
      );

      request.body = json.encode({
        "email": _emailController.text.trim(),
        "password": _passwordController.text.trim()
      });
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        final responseBytes = await response.stream.toBytes();
        final userData = json.decode(utf8.decode(responseBytes));

        final profileService = ProfileService();

        // 💡 서버 응답에서 memberId 추출 (int 또는 String 대응)
        final dynamic rawMemberId = userData['memberId'];
        int? memberIdInt;
        if (rawMemberId is int) {
          memberIdInt = rawMemberId;
        } else if (rawMemberId is String) {
          memberIdInt = int.tryParse(rawMemberId);
        }

        await profileService.saveProfile(
          name: userData['username'] ?? userData['nickname'] ?? '',
          studentId: _emailController.text.split('@')[0], // 예시: 이메일 앞자리를 학번 대용으로 사용하거나 적절한 필드 매핑
          phone: userData['phone'] ?? '',
          email: userData['email'] ?? '',
          accessToken: userData['accessToken'] ?? '',
          memberId: memberIdInt, // 💡 이제 int? 타입으로 안전하게 전달됩니다.
        );

        await profileService.generateAndSaveUniqueId();
        if (!mounted) return;
        widget.onLoginSuccess();
      }
    } catch (e) {
      debugPrint("Login Detail Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그인 중 오류가 발생했습니다.'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _loginFormKey,
            child: Column(
              children: [
                const Icon(Icons.lock_outline, size: 80, color: AppColors.primaryAlt),
                const SizedBox(height: 20),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: [
                        _buildInputField(
                          controller: _emailController,
                          label: '이메일',
                          hintText: 'example@university.ac.kr',
                          validator: (value) => (value == null || !value.contains('@')) ? '올바른 이메일 형식이 아닙니다.' : null,
                        ),
                        _buildInputField(
                          controller: _passwordController,
                          label: '비밀번호',
                          hintText: '비밀번호를 입력하세요',
                          obscureText: true,
                          validator: (value) => (value == null || value.isEmpty) ? '비밀번호를 입력해주세요.' : null,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                          child: const Text('로그인'),
                        ),
                        TextButton(onPressed: widget.onGoToSignUp, child: const Text('회원가입 하러가기')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: Colors.grey[100],
              errorStyle: const TextStyle(color: Colors.redAccent),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.redAccent)),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 2. 회원가입 화면 ---
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, required this.onGoToLogin});
  final VoidCallback onGoToLogin;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _signUpFormKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedGender = "MALE";

  Future<void> _handleSignUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;

    try {
      var headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
      var request = http.Request(
          'POST',
          Uri.parse('https://labchulseokbu-production.up.railway.app/lab/users/sign')
      );

      request.body = json.encode({
        "memberId": int.tryParse(_studentIdController.text.trim()) ?? 0,
        "nickname": _nameController.text.trim(),
        "password": _passwordController.text.trim(),
        "email": _emailController.text.trim(),
        "phone": _phoneController.text.trim(),
        "gender": _selectedGender,
      });
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBytes = await response.stream.toBytes();
        final userData = json.decode(utf8.decode(responseBytes));

        final profileService = ProfileService();

        // 💡 회원가입 응답에서도 서버가 부여한 진짜 ID를 추출합니다.
        final dynamic rawId = userData['memberId'];
        int? memberIdInt;
        if (rawId is int) {
          memberIdInt = rawId;
        } else if (rawId is String) {
          memberIdInt = int.tryParse(rawId);
        }

        await profileService.saveProfile(
          name: userData['username'] ?? userData['nickname'] ?? '',
          studentId: _studentIdController.text.trim(), // 입력한 학번 저장
          phone: userData['phone'] ?? '',
          email: userData['email'] ?? '',
          accessToken: userData['accessToken'] ?? '',
          memberId: memberIdInt, // 👈 서버가 준 진짜 ID 저장
        );
        await profileService.generateAndSaveUniqueId();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('회원가입 성공!')));
        widget.onGoToLogin();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('회원가입 실패: 정보를 확인하세요.')));
      }
    } catch (e) {
      debugPrint("SignUp Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onGoToLogin),
        title: const Text('회원가입', style: TextStyle(color: Colors.black)),
        backgroundColor: AppColors.authBackground,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _signUpFormKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Icon(Icons.person_add_alt_1, size: 50, color: AppColors.primaryAlt),
                const Text('회원가입', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildInputField(
                              controller: _nameController,
                              label: '이름',
                              hintText: '홍길동',
                              validator: (value) => (value == null || value.isEmpty) ? '이름을 입력해주세요.' : null,
                            ),
                            _buildInputField(
                              controller: _studentIdController,
                              label: '학번',
                              hintText: '20241234',
                              validator: (value) => (value == null || value.length < 8) ? '올바른 학번(8자리)을 입력하세요.' : null,
                            ),
                            _buildInputField(
                              controller: _phoneController,
                              label: '전화번호',
                              hintText: '010-1234-5678',
                              validator: (value) => (value == null || !value.contains('-')) ? '형식을 확인하세요 (- 포함).' : null,
                            ),
                            _buildInputField(
                              controller: _emailController,
                              label: '이메일',
                              hintText: 'example@university.ac.kr',
                              validator: (value) => (value == null || !value.contains('@')) ? '이메일 형식이 아닙니다.' : null,
                            ),
                            _buildInputField(
                              controller: _passwordController,
                              label: '비밀번호',
                              hintText: '8자리 이상',
                              obscureText: true,
                              validator: (value) => (value == null || value.length < 8) ? '8자리 이상 입력하세요.' : null,
                            ),
                            const Align(alignment: Alignment.centerLeft, child: Text('성별', style: TextStyle(fontWeight: FontWeight.bold))),
                            DropdownButtonFormField<String>(
                              value: _selectedGender,
                              items: const [
                                DropdownMenuItem(value: "MALE", child: Text("남성")),
                                DropdownMenuItem(value: "FEMALE", child: Text("여성")),
                              ],
                              onChanged: (v) => setState(() => _selectedGender = v!),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAlt,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('가입하기', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: Colors.grey[100],
              errorStyle: const TextStyle(color: Colors.redAccent),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.redAccent)),
            ),
          ),
        ],
      ),
    );
  }
}