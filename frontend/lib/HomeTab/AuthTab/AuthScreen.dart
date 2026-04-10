import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/HomeTab/Views/Profile_Service.dart';
import 'package:frontend/services/api_client.dart';
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
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
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
        final String accessToken = userData['accessToken'] ?? ''; // 토큰 가져오기

        // 💡 [핵심 추가] ApiClient에 토큰을 설정합니다.
        // ApiClient 클래스에 setToken 메서드가 정의되어 있어야 합니다.
        ApiClient.instance.setToken(accessToken);

        // 기존 프로필 저장 로직
        final dynamic rawMemberId = userData['memberId'];
        int? memberIdInt = (rawMemberId is int) ? rawMemberId : int.tryParse(rawMemberId?.toString() ?? '');

        await profileService.saveProfile(
          name: userData['username'] ?? userData['nickname'] ?? '',
          studentId: userData['studentId']?.toString() ?? memberIdInt?.toString() ?? '',
          phone: userData['phone'] ?? '',
          email: userData['email'] ?? '',
          accessToken: accessToken, // 변수 사용
          memberId: memberIdInt,
        );

        await profileService.generateAndSaveUniqueId();
        if (!mounted) return;
        widget.onLoginSuccess();
      } else {
        if (!mounted) return;
        debugPrint('[login] 실패: 이메일 또는 비밀번호 불일치');
      }
    } catch (e) {
      debugPrint("Login Detail Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Form(
              key: _loginFormKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 상단 로고 아이콘
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    '랩실 출석부',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '로그인하여 시작하세요',
                    style: TextStyle(fontSize: 15, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 44),

                  // 로그인 카드
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 12)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('이메일'),
                        _buildTextField(
                          controller: _emailController,
                          hintText: 'example@university.ac.kr',
                          validator: (value) => (value == null || !value.contains('@')) ? '올바른 이메일 형식이 아닙니다.' : null,
                        ),
                        const SizedBox(height: 24),
                        _buildLabel('비밀번호'),
                        _buildTextField(
                          controller: _passwordController,
                          hintText: '비밀번호를 입력하세요',
                          obscureText: true,
                          validator: (value) => (value == null || value.isEmpty) ? '비밀번호를 입력해주세요.' : null,
                        ),
                        const SizedBox(height: 36),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isLoading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('로그인', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('계정이 없으신가요? ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                            GestureDetector(
                              onTap: widget.onGoToSignUp,
                              child: const Text('회원가입', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hintText, bool obscureText = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        errorStyle: const TextStyle(color: AppColors.error),
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
  bool _isLoading = false;

  Future<void> _handleSignUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final String inputStudentId = _studentIdController.text.trim();
    try {
      var headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
      var request = http.Request('POST', Uri.parse('https://labchulseokbu-production.up.railway.app/lab/users/sign'));

      int memberIdValue = int.tryParse(inputStudentId) ?? 0;
      request.body = json.encode({
        "memberId": memberIdValue,
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

        final dynamic rawId = userData['memberId'];
        int? memberIdInt = (rawId is int) ? rawId : int.tryParse(rawId?.toString() ?? '');
        memberIdInt ??= memberIdValue;

        await profileService.saveProfile(
          name: userData['username'] ?? userData['nickname'] ?? _nameController.text.trim(),
          studentId: inputStudentId,
          phone: userData['phone'] ?? _phoneController.text.trim(),
          email: userData['email'] ?? _emailController.text.trim(),
          accessToken: userData['accessToken'] ?? '',
          memberId: memberIdInt,
        );
        await profileService.generateAndSaveUniqueId();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('회원가입 성공!')));
        widget.onGoToLogin();
      } else {
        if (!mounted) return;
        debugPrint('[signup] 실패 status=${response.statusCode}');
      }
    } catch (e) {
      debugPrint("SignUp Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20), onPressed: widget.onGoToLogin),
        title: const Text('회원가입', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _signUpFormKey,
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text('새로운 계정 만들기', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5)),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('이름'),
                      _buildTextField(controller: _nameController, hintText: '홍길동', validator: (v) => (v == null || v.isEmpty) ? '이름을 입력해주세요.' : null),
                      const SizedBox(height: 20),
                      _buildLabel('학번'),
                      _buildTextField(controller: _studentIdController, hintText: '20241234', validator: (v) => (v == null || v.length < 8) ? '학번 8자리를 입력하세요.' : null),
                      const SizedBox(height: 20),
                      _buildLabel('전화번호'),
                      _buildTextField(controller: _phoneController, hintText: '010-1234-5678', validator: (v) => (v == null || !v.contains('-')) ? '형식을 확인하세요.' : null),
                      const SizedBox(height: 20),
                      _buildLabel('이메일'),
                      _buildTextField(controller: _emailController, hintText: 'example@university.ac.kr', validator: (v) => (v == null || !v.contains('@')) ? '이메일 형식이 아닙니다.' : null),
                      const SizedBox(height: 20),
                      _buildLabel('비밀번호'),
                      _buildTextField(controller: _passwordController, hintText: '8자리 이상', obscureText: true, validator: (v) => (v == null || v.length < 8) ? '8자리 이상 입력하세요.' : null),
                      const SizedBox(height: 20),
                      _buildLabel('성별'),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                        items: const [
                          DropdownMenuItem(value: "MALE", child: Text("남성")),
                          DropdownMenuItem(value: "FEMALE", child: Text("여성")),
                        ],
                        onChanged: (v) => setState(() => _selectedGender = v!),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('회원가입 완료', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hintText, bool obscureText = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        errorStyle: const TextStyle(color: AppColors.error),
      ),
    );
  }
}