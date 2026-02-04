import 'package:flutter/material.dart';

// 랩실 상태를 정의하는 enum
enum LabStatus { inLab, outLab }

const Color White = Color(0xFFFFFFFF);
const Color Grey = Color(0xFF9CA3AF);
const Color LightGrey = Color(0xFFE5E7EB); // 비활성화된 버튼 배경색
const Color mainOrange = Color(0xFFF97316); // 메인 컬러

// 화면의 한 부분을 구성하는 메인 상태 관리 위젯
class LabStatusCard extends StatefulWidget {
  const LabStatusCard({super.key});

  @override
  State<LabStatusCard> createState() => _LabStatusCardState();
}

class _LabStatusCardState extends State<LabStatusCard> {
  // 현재 랩실 상태를 저장하는 변수 (기본값: 랩실 밖에 있음)
  LabStatus _currentStatus = LabStatus.outLab;

  // 상태 업데이트 함수
  void _updateStatus(LabStatus newStatus) {
    if (_currentStatus != newStatus) {
      setState(() {
        _currentStatus = newStatus;
      });
      // 실제 로직에서는 여기에 서버 통신 등을 추가합니다.
      print('Status updated to: ${_currentStatus == LabStatus.inLab ? 'In Lab' : 'Out Lab'}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 시각적 구분을 위해 Card 위젯 사용
    return Card(
      color: const Color(0xFFFFFFFF),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        // 모든 요소를 세로로 배치
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
          children: [
            // 1. 섹션 제목
            const Text(
              '랩실 상태',
              style: TextStyle(
                fontSize: 15.3,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16), // 간격

            // 2. 현재 상태 표시 영역 (상태 변수에 따라 텍스트/색상 변경)
            _CurrentStatus(status: _currentStatus),
            const SizedBox(height: 16), // 간격

            // 3. 들어오기/나가기 버튼 영역 (상태 업데이트 함수 전달)
            _InOutButtons(
              currentStatus: _currentStatus,
              onUpdateStatus: _updateStatus,
            ),
            const SizedBox(height: 16), // 간격

            // 4. 직접 상태 변경 토글 영역 (상태와 연동)
            _ManualToggle(
              currentStatus: _currentStatus,
              onStatusChanged: _updateStatus,
            ),
          ],
        ),
      ),
    );
  }
}

// --- 하위 위젯들을 분리하여 구현 (가독성 향상) ---

// 2. 현재 상태 표시 위젯 (LabStatus를 받아 상태에 따라 내용 변경)
class _CurrentStatus extends StatelessWidget {
  final LabStatus status;
  const _CurrentStatus({required this.status});

  @override
  Widget build(BuildContext context) {
    // 상태에 따른 텍스트 및 색상 설정
    final isInLab = status == LabStatus.inLab;
    final statusText = isInLab ? '랩실 안에 있습니다' : '랩실 밖에 있습니다';
    final statusDetail = isInLab ? '마지막 체크인: 오늘 09:45' : '마지막 체크아웃: 어제 18:30';
    final statusColor = isInLab ? Colors.green.shade600 : Grey;

    // 아이콘과 텍스트를 가로로 배치
    return Row(
      children: [
        // 시계 아이콘 (색상 변화)
        Icon(Icons.schedule, size: 64, color: statusColor),
        const SizedBox(width: 16),
        // 상태 텍스트
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              statusText,
              style: TextStyle(
                fontSize: 15.3,
                color: statusColor, // 색상 변화
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
                statusDetail,
                style: const TextStyle(fontSize: 11.9, color: Grey)
            ),
          ],
        ),
      ],
    );
  }
}

// 3. 들어오기/나가기 버튼 위젯 (상태에 따라 스타일 변화)
class _InOutButtons extends StatelessWidget {
  final LabStatus currentStatus;
  final Function(LabStatus) onUpdateStatus;

  const _InOutButtons({required this.currentStatus, required this.onUpdateStatus});

  @override
  Widget build(BuildContext context) {
    final isInLab = currentStatus == LabStatus.inLab;

    // 들어오기: 랩실 밖일 때 주황(활성), 랩실 안일 때 회색 테두리
    // 나가기: 랩실 안일 때 주황(활성), 랩실 밖일 때 회색 테두리
    final inActive = !isInLab; // 랩실 밖에 있으면 들어오기가 주 액션
    final outActive = isInLab; // 랩실 안에 있으면 나가기가 주 액션

    return Row(
      children: [
        // 들어오기 버튼 (IN_LAB) - 오른쪽 화살표
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: inActive
                ? ElevatedButton.icon(
                    onPressed: () => onUpdateStatus(LabStatus.inLab),
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    label: const Text('들어오기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainOrange,
                      foregroundColor: White,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: () => onUpdateStatus(LabStatus.inLab),
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    label: const Text('들어오기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Grey,
                      side: const BorderSide(color: LightGrey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
          ),
        ),
        // 나가기 버튼 (OUT_LAB) - 왼쪽 화살표
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: outActive
                ? ElevatedButton.icon(
                    onPressed: () => onUpdateStatus(LabStatus.outLab),
                    icon: const Icon(Icons.arrow_back_ios, size: 16),
                    label: const Text('나가기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainOrange,
                      foregroundColor: White,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: () => onUpdateStatus(LabStatus.outLab),
                    icon: const Icon(Icons.arrow_back_ios, size: 16),
                    label: const Text('나가기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Grey,
                      side: const BorderSide(color: LightGrey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// 4. 직접 상태 변경 토글 위젯
// 토글 ON = 랩실 안 (나가기 주황), 토글 OFF = 랩실 밖 (들어오기 주황)
// 들어오기 누르면 토글 ON, 나가기 누르면 토글 OFF
class _ManualToggle extends StatelessWidget {
  final LabStatus currentStatus;
  final Function(LabStatus) onStatusChanged;

  const _ManualToggle({
    required this.currentStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isInLab = currentStatus == LabStatus.inLab;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('직접 상태 변경', style: TextStyle(fontSize: 14, color: Grey)),
        Switch(
          value: isInLab, // 토글 ON = 랩실 안
          onChanged: (bool newValue) {
            onStatusChanged(newValue ? LabStatus.inLab : LabStatus.outLab);
          },
          activeTrackColor: mainOrange.withOpacity(0.5),
          activeThumbColor: White,
          inactiveThumbColor: White,
          inactiveTrackColor: const Color(0xFFD1D5DB),
          trackOutlineWidth: WidgetStateProperty.all(0),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ],
    );
  }
}