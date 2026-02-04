import 'package:flutter/material.dart';
import 'Profile_Service.dart';

const Color primaryOrange = Color(0xFFE8823A);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '출석부 데모',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryOrange),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProfileService profileService = ProfileService();

  String name = '';
  String studentId = '';
  String phone = '';
  String email = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final profileData = await profileService.loadProfile();
    if (mounted) {
      setState(() {
        name = profileData['name']!;
        studentId = profileData['studentId']!;
        phone = profileData['phone']!;
        email = profileData['email']!;
        _isLoading = false;
      });
    }
  }

  Future<void> _resetProfile() async {
    await profileService.clearProfile();
    await _loadProfileData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필이 초기화되었습니다.'), duration: Duration(seconds: 2)),
      );
    }
  }

  // 다이얼로그를 보여주는 함수가 매우 간결해졌습니다.
  void _showEditProfileDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        // 별도로 분리된 다이얼로그 위젯을 호출합니다.
        return EditProfileDialog(
          initialName: name,
          initialStudentId: studentId,
          initialPhone: phone,
          initialEmail: email,
          onSave: (newName, newId, newPhone, newEmail) async {
            // 저장 로직은 HomePage에서 그대로 처리합니다.
            await profileService.saveProfile(
              name: newName,
              studentId: newId,
              phone: newPhone,
              email: newEmail,
            );

            if (mounted) {
              setState(() {
                name = newName;
                studentId = newId;
                phone = newPhone;
                email = newEmail;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('프로필이 저장되었습니다.'), duration: Duration(seconds: 2)),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // HomePage의 UI 코드는 변경이 없습니다.
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0.6,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: const Row(
          children: [
            Icon(Icons.book_outlined, color: primaryOrange),
            SizedBox(width: 8),
            Text('출석부', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _resetProfile,
            tooltip: '프로필 초기화',
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.0)),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              child: Row(
                children: [
                  Text(name, style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _showEditProfileDialog,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: primaryOrange,
                      child: Text(
                        name.isNotEmpty ? name[0] : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '오른쪽 상단 프로필을 눌러 정보를 수정하세요.\n앱을 종료해도 데이터는 유지됩니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 다이얼로그의 내용물을 별도의 StatefulWidget으로 분리
// -----------------------------------------------------------------------------
class EditProfileDialog extends StatefulWidget {
  final String initialName;
  final String initialStudentId;
  final String initialPhone;
  final String initialEmail;
  final Future<void> Function(String name, String studentId, String phone, String email) onSave;
  final VoidCallback? onLogout;

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
  // State 내부에 컨트롤러를 선언합니다.
  late final TextEditingController nameController;
  late final TextEditingController idController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;

  @override
  void initState() {
    super.initState();
    // initState에서 컨트롤러를 안전하게 생성합니다.
    nameController = TextEditingController(text: widget.initialName);
    idController = TextEditingController(text: widget.initialStudentId);
    phoneController = TextEditingController(text: widget.initialPhone);
    emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    // 위젯이 제거될 때 Flutter가 자동으로 호출해주는 dispose에서 컨트롤러를 해제합니다.
    nameController.dispose();
    idController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  // 재사용 가능한 입력 필드 위젯
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryOrange, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('프로필 수정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  IconButton(
                    splashRadius: 20,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: nameController,
                  builder: (context, value, _) {
                    final txt = value.text;
                    final firstChar = txt.isNotEmpty ? txt[0] : (widget.initialName.isNotEmpty ? widget.initialName[0] : '?');
                    return CircleAvatar(
                      radius: 36,
                      backgroundColor: primaryOrange.withOpacity(0.1),
                      child: Text(
                        firstChar,
                        style: const TextStyle(fontSize: 28, color: primaryOrange, fontWeight: FontWeight.w600),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              _buildInputField(controller: nameController, hint: '이름', icon: Icons.person),
              const SizedBox(height: 10),
              _buildInputField(controller: idController, hint: '학번', icon: Icons.bookmark_outline),
              const SizedBox(height: 10),
              _buildInputField(controller: phoneController, hint: '전화번호', icon: Icons.phone),
              const SizedBox(height: 10),
              _buildInputField(controller: emailController, hint: '이메일', icon: Icons.email_outlined),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      foregroundColor: Colors.black87,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      await widget.onSave(
                        nameController.text.trim(),
                        idController.text.trim(),
                        phoneController.text.trim(),
                        emailController.text.trim(),
                      );
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('저장'),
                  ),
                ],
              ),
              if (widget.onLogout != null) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onLogout!();
                    },
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text('로그아웃'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
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