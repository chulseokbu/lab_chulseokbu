import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';

class EditProfileDialog extends StatefulWidget {
  final String initialNickname;
  final String initialStudentId;
  final String initialPhone;
  final String initialEmail;
  final Future<void> Function(String nickname, String studentId) onSave;
  final VoidCallback? onLogout;
  /// 성공 시 `null`, 실패 시 사용자에게 보여줄 메시지
  final Future<String?> Function()? onWithdrawAccount;

  const EditProfileDialog({
    super.key,
    required this.initialNickname,
    required this.initialStudentId,
    required this.initialPhone,
    required this.initialEmail,
    required this.onSave,
    this.onLogout,
    this.onWithdrawAccount,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late final TextEditingController nameController;
  late final TextEditingController idController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialNickname);
    idController = TextEditingController(text: widget.initialStudentId);
    phoneController = TextEditingController(text: widget.initialPhone);
    emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    nameController.dispose();
    idController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _showWithdrawFlow() async {
    if (widget.onWithdrawAccount == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text(
          '탈퇴 시 계정과 관련 데이터가 삭제됩니다.\n정말 탈퇴할까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('탈퇴', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final message = await widget.onWithdrawAccount!();
    if (!mounted) return;
    if (message == null) {
      Navigator.of(context).pop(true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.authBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: const Icon(Icons.person_rounded,
                          size: 50, color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 55),
            const Text(
              '내 정보 수정',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildProfileTextField(
                      label: '닉네임',
                      controller: nameController,
                      icon: Icons.badge_outlined),
                  const SizedBox(height: 16),
                  _buildProfileTextField(
                      label: '학번',
                      controller: idController,
                      icon: Icons.school_outlined),
                  const SizedBox(height: 16),
                  _buildReadOnlyField(
                      label: '전화번호',
                      controller: phoneController,
                      icon: Icons.phone_android_rounded),
                  const SizedBox(height: 16),
                  _buildReadOnlyField(
                      label: '이메일',
                      controller: emailController,
                      icon: Icons.alternate_email_rounded),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('취소',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await widget.onSave(
                          nameController.text.trim(),
                          idController.text.trim(),
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('저장하기',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.onLogout != null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('로그아웃'),
                        content: const Text(
                          '로그아웃하면 다시 로그인해야 합니다.\n계속할까요?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              '로그아웃',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (ok != true || !context.mounted) return;
                    Navigator.pop(context);
                    widget.onLogout!();
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    foregroundColor: AppColors.error,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('로그아웃', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
            if (widget.onWithdrawAccount != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextButton(
                  onPressed: _showWithdrawFlow,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: const Text('회원 탈퇴',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary),
          ),
        ),
        TextField(
          controller: controller,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.background,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary),
          ),
        ),
        TextField(
          controller: controller,
          readOnly: true,
          enableInteractiveSelection: true,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary.withOpacity(0.65),
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade500),
            filled: true,
            fillColor: AppColors.background.withOpacity(0.85),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 6),
          child: Text(
            '가입 시 등록된 정보는 변경할 수 없습니다.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }
}
