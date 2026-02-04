// lib/notification_view.dart
import 'dart:async'; //타이머 기능
import 'package:flutter/material.dart';

// -----------------------------------------------------------------
//
// -----------------------------------------------------------------

// 알림의 상태를 구분하는 열거형
enum AlarmStatus {
  pending,//보류 중: 알림이 등록되었지만, 아직 울릴 시간이 아님
  active, // "랩실에 계신가요?" 팝업이 활성화 되어 카운트 됨
  respondedYes, // 사용자의 대답이 yes
  respondedNo, // 사용자의 대답이 no
  timedOut, // 사용자가 응답하지 않아 시간이 초과됨
}

// 각 알림 항목이 가질 데이터 모델
class AlarmData {//final(변경불가) 함수들
  final String id;
  final String time;
  final String date;
  final AlarmStatus status;
  final Duration? initialCountdown; //?는 null이 될 수 있다는 의미

  const AlarmData({
    required this.id,
    required this.time,
    required this.date,
    required this.status, //required는 필수적이라는 뜻, 없으면 선택적
    this.initialCountdown, //초기 남은 시간//필수적이지 않은 이유: 모든 알림이 카운트다운을 가질 필요가 없음
  });
}

const Color _mainOrange = Color(0xFFF97316);

// 알림 화면 전체를 구성하는 위젯
class NotificationView extends StatelessWidget {
  const NotificationView({super.key, this.embedded = false});

  /// 홈 탭에 카드 형태로 임베드할 때 true
  final bool embedded;

  // 이 데이터는 실제로는 서버나 데이터베이스에서 받아와야 함
  final List<AlarmData> mockAlarms = const [
    AlarmData(
      id: '1',
      time: '11:15',
      date: '오늘',
      status: AlarmStatus.active,
      initialCountdown: Duration(minutes: 15),
    ),
    AlarmData(
      id: '2',
      time: '09:15',
      date: '오늘',
      status: AlarmStatus.respondedYes,
    ),
    AlarmData(
      id: '3',
      time: '17:15',
      date: '어제',
      status: AlarmStatus.timedOut,
    ),
    AlarmData(
      id: '4',
      time: '11:15',
      date: '오늘',
      status: AlarmStatus.pending,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return Card(
        color: const Color(0xFFFFFFFF),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '알림',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...mockAlarms.take(3).map((alarm) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: AlarmCard(alarm: alarm),
                  )),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: mockAlarms.length,
        itemBuilder: (context, index) {
          return AlarmCard(alarm: mockAlarms[index]);
        },
      ),
    );
  }
}

// 개별 알림 카드의 UI와 로직을 담당하는 위젯
class AlarmCard extends StatefulWidget {//부모로부터 alarmdata를 전달받음
  final AlarmData alarm;
  const AlarmCard({super.key, required this.alarm});
  @override
  State<AlarmCard> createState() => _AlarmCardState();
}

class _AlarmCardState extends State<AlarmCard> {//이 위젯의 상태를 관리하는 실제 로직이 들어있는 곳
  late AlarmStatus _currentStatus;
  Timer? _countdownTimer;
  late Duration _remainingTime;
  late Duration _totalDuration;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.alarm.status;//부모로부터 받은 초기 상태를 설정
    if (_currentStatus == AlarmStatus.active) {
      _totalDuration = const Duration(minutes: 20);
      _remainingTime = widget.alarm.initialCountdown ?? _totalDuration;
      startTimer();//만약 상태가 active(활성)라면, 남은 시간을 설정하고, start Timer를 호출해 카운트다운 시작
    }
  }

  void startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {//1초마다 timer안의 코드 실행
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {//상태가 바뀌었을 때 화면을 새로 그리라고 명령하는 함수
        if (_remainingTime.inSeconds > 0) {//0초보다 많이 남았으면 _remainingTime 에서 1초를 뺌
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        } else {//남은 시간이 0초면 차이머를 멈추고 상태를 시간초과로 변경 및 자동 퇴실 처리
          timer.cancel();
          _currentStatus = AlarmStatus.timedOut;
        }
      });
    });
  }

  @override
  void dispose() {//위젯이 화면에서 사라질 때 실행
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onRespondYes() {
    _countdownTimer?.cancel();
    setState(() { _currentStatus = AlarmStatus.respondedYes; });
    print("User responded: YES to alarm ${widget.alarm.id}");
  }

  void _onRespondNo() {
    _countdownTimer?.cancel();
    setState(() { _currentStatus = AlarmStatus.respondedNo; });
    print("User responded: NO to alarm ${widget.alarm.id}");
  }

  @override
  Widget build(BuildContext context) {//알림 카드 디자인
    // 아직 응답 안 했을 때(active, pending): FED7AA / 응답 완료 시: F9FAFB
    final bool needsResponse = _currentStatus == AlarmStatus.active || _currentStatus == AlarmStatus.pending;
    final Color cardColor = needsResponse ? const Color(0xFFFFF7ED) : const Color(0xFFF9FAFB);

    return Card(
      color: cardColor,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _currentStatus == AlarmStatus.timedOut ? Icons.warning_amber_rounded : Icons.notifications_none_outlined,
                  color: _currentStatus == AlarmStatus.timedOut ? Colors.red : Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '랩실에 계신가요?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                ),
                const Spacer(),
                Text(widget.alarm.time, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(widget.alarm.date, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 12),
              child: _buildStatusSection(),
            ),
          ],
        ),
      ),
    );
  }//setState가 호출될 때마다 매번 다시 실행
  // _currentStatus를 확인해 cardColor와 borderColor을 결정, 아이콘도 경고아이콘/알림아이콘 결정
//텍스트들을 배치
  Widget _buildStatusSection() {//_currentStatus값에 따라 완전히 다른 ui를 반환
    switch (_currentStatus) {
      case AlarmStatus.active://활성 상태
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildResponseButton(icon: Icons.check, color: Colors.green, onPressed: _onRespondYes),
                const SizedBox(width: 12),
                _buildResponseButton(icon: Icons.close, color: Colors.red, onPressed: _onRespondNo),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _remainingTime.inSeconds / _totalDuration.inSeconds,
              backgroundColor: Colors.grey[300],
              color: _mainOrange,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 6),
            Text(
              '${_remainingTime.inMinutes}분 ${(_remainingTime.inSeconds % 60).toString().padLeft(2, '0')}초 남음',
              style: const TextStyle(color: _mainOrange, fontWeight: FontWeight.bold),
            ),
          ],
        );
      case AlarmStatus.respondedYes://예 응답
        return const Text(
          '✓ 응답함: 랩실에 있음',
          style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 15),
        );
      case AlarmStatus.respondedNo://아니요 응답
        return const Text(
          '✓ 응답함: 랩실에 없음',
          style: TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.bold, fontSize: 15),
        );
      case AlarmStatus.timedOut:
        return const Text(
          '! 자동 퇴실 처리됨 (무응답)',
          style: TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.bold, fontSize: 15),
        );
      case AlarmStatus.pending:
        return const SizedBox.shrink();
    }
  }
//예, 아니요 버튼을 디자인은 같게, 기능과 아이콘, 색상만 다르게 만듦
  Widget _buildResponseButton({required IconData icon, required Color color, required VoidCallback onPressed}) {
    return Material(
      color: color.withOpacity(0.1),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        splashColor: color.withOpacity(0.3),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}
void main() {
  runApp(
    //내 화면(NotificationView)만 단독으로 실행하는 테스트용 앱
    MaterialApp(
      title: 'Notification View Test',
      home: NotificationView(),
    ),
  );
}