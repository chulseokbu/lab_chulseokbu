import 'package:flutter/material.dart';
import 'Profile_Service.dart';

const Color primaryOrange = Color(0xFFE8823A);

// -----------------------------------------------------------------------------
// 프로필 수정 다이얼로그 위젯 (onLogout 포함)
// -----------------------------------------------------------------------------
class EditProfileDialog extends StatefulWidget {
  final String initialName;
  final String initialStudentId;
  final String initialPhone;
  final String initialEmail;
  final Future<void> Function(String name, String studentId, String phone, String email) onSave;
  final VoidCallback? onLogout; // 💡 로그아웃 콜백 추가

  const EditProfileDialog({
    super.key,
    required this.initialName,
    required this.initialStudentId,
    required this.initialPhone,
    required this.initialEmail,
    required this.onSave,
    this.onLogout,
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
    nameController = TextEditingController(text: widget.initialName);
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('프로필 수정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: '이름')),
              TextField(controller: idController, decoration: const InputDecoration(labelText: '학번')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: '전화번호')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: '이메일')),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
                  ElevatedButton(
                    onPressed: () async {
                      await widget.onSave(
                        nameController.text.trim(),
                        idController.text.trim(),
                        phoneController.text.trim(),
                        emailController.text.trim(),
                      );
                      if (mounted) Navigator.pop(context);
                    },
                    child: const Text('저장'),
                  ),
                ],
              ),
              if (widget.onLogout != null) ...[
                const Divider(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onLogout!();
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('로그아웃', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}