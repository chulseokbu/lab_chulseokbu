import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/apple_auth_service.dart';
import 'package:frontend/services/auth_service.dart';

/// 애플 최초 로그인 후 서버에 제출할 랩실 프로필
class AppleOnboardingScreen extends StatefulWidget {
  const AppleOnboardingScreen({
    super.key,
    required this.identityToken,
    this.authorizationCode,
    this.userIdentifier,
    this.emailHint,
    this.nicknameHint,
    required this.onComplete,
  });

  final String identityToken;
  final String? authorizationCode;
  final String? userIdentifier;
  final String? emailHint;
  final String? nicknameHint;
  final VoidCallback onComplete;

  @override
  State<AppleOnboardingScreen> createState() => _AppleOnboardingScreenState();
}

class _AppleOnboardingScreenState extends State<AppleOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _gender = 'MALE';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.emailHint != null && widget.emailHint!.isNotEmpty) {
      _emailController.text = widget.emailHint!;
    }
    if (widget.nicknameHint != null && widget.nicknameHint!.isNotEmpty) {
      _nameController.text = widget.nicknameHint!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final studentId = int.tryParse(_studentIdController.text.trim()) ?? 0;
      final dto = await AppleAuthService.instance.completeAppleProfile(
        identityToken: widget.identityToken,
        authorizationCode: widget.authorizationCode,
        userIdentifier: widget.userIdentifier,
        memberId: studentId,
        nickname: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        gender: _gender,
      );
      await AuthService.instance.applyLoginSuccess(dto);
      if (!mounted) return;
      if (!ApiClient.instance.hasToken) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '로그인 토큰을 받지 못했습니다. 서버 응답에 accessToken(또는 token) 필드가 있는지 확인해주세요.',
            ),
          ),
        );
        return;
      }
      widget.onComplete();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '프로필 입력',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  '애플 계정으로 처음 로그인했어요.\n가능하면 이메일은 Apple에서 가져왔어요. 닉네임·전화번호·학번을 입력해주세요.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('이메일'),
                      _field(
                        controller: _emailController,
                        hint: 'example@university.ac.kr',
                        validator: (v) => (v == null || !v.contains('@'))
                            ? '이메일 형식이 아닙니다.'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _label('닉네임 (랩실용)'),
                      _field(
                        controller: _nameController,
                        hint: '랩실에서 쓸 닉네임',
                        validator: (v) =>
                            (v == null || v.isEmpty) ? '닉네임을 입력해주세요.' : null,
                      ),
                      const SizedBox(height: 20),
                      _label('전화번호'),
                      _field(
                        controller: _phoneController,
                        hint: '010-1234-5678',
                        validator: (v) => (v == null || !v.contains('-'))
                            ? '형식을 확인하세요.'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _label('학번'),
                      _field(
                        controller: _studentIdController,
                        hint: '20241234',
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null || v.length < 8) ? '학번 8자리를 입력하세요.' : null,
                      ),
                      const SizedBox(height: 20),
                      _label('성별'),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'MALE', child: Text('남성')),
                          DropdownMenuItem(value: 'FEMALE', child: Text('여성')),
                        ],
                        onChanged: (v) => setState(() => _gender = v!),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  '가입 완료',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(color: AppColors.error),
      ),
    );
  }
}
