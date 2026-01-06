import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

// Meeting Model
class Meeting {
  String code;
  String name;
  List<String> members;

  Meeting({
    required this.code,
    required this.name,
    required this.members,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "모임 관리",
      home: const MeetingListScreen(),
    );
  }
}

// ─────────────────────────────────────────────
//  메인 화면: 모임 리스트
// ─────────────────────────────────────────────
class MeetingListScreen extends StatefulWidget {
  const MeetingListScreen({super.key});

  @override
  State<MeetingListScreen> createState() => _MeetingListScreenState();
}

class _MeetingListScreenState extends State<MeetingListScreen> {
  final List<Meeting> meetings = [];

  // 모임 코드 랜덤 생성
  String generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  // 모임 생성
  void createMeeting() {
    TextEditingController nameController = TextEditingController();
    String generatedCode = generateCode();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("새 모임 생성"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "모임 이름"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("취소"),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;

                setState(() {
                  meetings.add(
                    Meeting(
                      code: generatedCode,
                      name: nameController.text,
                      members: [],
                    ),
                  );
                });

                Navigator.pop(context);
              },
              child: Text("생성 (코드: $generatedCode)"),
            ),
          ],
        );
      },
    );
  }

  // 모임 참여
  void joinMeeting() {
    TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("모임 참여"),
          content: TextField(
            controller: codeController,
            decoration: const InputDecoration(labelText: "모임 코드 입력"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("취소"),
            ),
            ElevatedButton(
              onPressed: () {
                String code = codeController.text.trim();
                Meeting? target;

                for (var m in meetings) {
                  if (m.code == code) target = m;
                }

                setState(() {
                  if (target != null) {
                    if (!target.members.contains("김")) {
                      target.members.add("김"); // 예시
                    }
                  } else {
                    // 존재하지 않으면 새 모임 생성
                    meetings.add(Meeting(
                      code: code,
                      name: "새 모임 ($code)",
                      members: ["김"],
                    ));
                  }
                });

                Navigator.pop(context);
              },
              child: const Text("참여"),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────
  //        UI
  // ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("모임 목록"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: createMeeting,
          ),
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: joinMeeting,
          )
        ],
      ),
      body: ListView.builder(
        itemCount: meetings.length,
        itemBuilder: (context, index) {
          final meeting = meetings[index];
          return ListTile(
            title: Text(meeting.name),
            subtitle: Text("코드: ${meeting.code}"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MeetingDetailScreen(
                    meeting: meeting,
                    onUpdate: () => setState(() {}),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//        모임 상세 화면 (멤버 표시 없음)
// ─────────────────────────────────────────────
class MeetingDetailScreen extends StatefulWidget {
  final Meeting meeting;
  final VoidCallback onUpdate;

  const MeetingDetailScreen({
    super.key,
    required this.meeting,
    required this.onUpdate,
  });

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen> {
  void editName() {
    TextEditingController controller =
    TextEditingController(text: widget.meeting.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("모임 이름 변경"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: "새 이름"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("취소"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  widget.meeting.name = controller.text;
                });
                widget.onUpdate();
                Navigator.pop(context);
              },
              child: const Text("확인"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final meeting = widget.meeting;

    return Scaffold(
      appBar: AppBar(
        title: const Text("모임 상세"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 모임 이름
            Row(
              children: [
                Text(
                  meeting.name,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: editName,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 모임 코드 + 복사
            Row(
              children: [
                Text("모임 코드: ${meeting.code}",
                    style: const TextStyle(fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: meeting.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("코드 복사됨!")),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 40),

            const Text(
              "구성원은 이 화면에서 표시되지 않습니다.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
