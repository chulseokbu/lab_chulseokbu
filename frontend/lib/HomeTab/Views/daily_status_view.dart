import 'package:flutter/material.dart';

const Color _mainOrange = Color(0xFFF97316);

// 1. 출석 기록을 위한 간단한 데이터 모델 (변동 없음)
class AttendanceRecord {
  final String date;
  final String status;
  final String checkIn;
  final String checkOut;
//record
  AttendanceRecord({
    required this.date,
    required this.status,
    required this.checkIn,
    required this.checkOut,
  });
}

// 2. 이 파일의 메인 위젯 (StatefulWidget) (변동 없음)
class DailyStatusView extends StatefulWidget {
  const DailyStatusView({super.key});

  @override
  State<DailyStatusView> createState() => _DailyStatusViewState();
}

class _DailyStatusViewState extends State<DailyStatusView> {
  // 3. 탭 버튼의 상태를 관리할 변수 - 왼쪽(그리드) 기본 선택
  bool _isListView = false; // false: 그리드(네모 4개), true: 리스트

  // 30일치 더미 데이터 생성 함수 (위치 유지)
  List<AttendanceRecord> _generateDummyData(int count) {
    return List.generate(count, (index) {
      final day = 30 - index;
      return AttendanceRecord(
        date: '8월 $day일 (${['월', '화', '수', '목', '금', '토', '일'][index % 7]})',
        status: (index % 10 == 0) ? '결석' : '출석',
        checkIn: (index % 10 == 0) ? '' : '9:${index + 10}', // 결석 시 데이터 비워둠
        checkOut: (index % 10 == 0) ? '' : '18:${index + 20}', // 결석 시 데이터 비워둠
      );
    });
  }

  // ⭐ build 메서드 수정: _buildContentArea를 Expanded의 child로 직접 호출
  @override
  Widget build(BuildContext context) {
    // 4. AppBar, BottomNav 제거. SafeArea 추가
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Scaffold 배경색
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 5. 요청한 새 헤더 (제목 + 탭 버튼)
              _buildHeader(),
              const SizedBox(height: 16),

              // 6. 출석 빈도 (홈 탭과 동일)
              _buildAttendanceFrequencySection(),
              const SizedBox(height: 16),

              // 7. 스크롤 가능한 리스트 영역
              Expanded(
                // ⭐ 수정된 부분: _buildContentArea를 직접 호출
                child: _buildContentArea(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 위젯 빌드 헬퍼 함수 ---

  // 8. 헤더 위젯 (백 버튼 + 제목 + 탭 버튼)
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            const Text(
              '랩실 구성원 출석 현황',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        _buildToggleButtons(), // 탭 버튼
      ],
    );
  }

  // 9. 탭 버튼 위젯 - 왼쪽: 그리드(네모 4개), 오른쪽: 리스트
  Widget _buildToggleButtons() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFECECEC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildToggleButton(Icons.grid_view_rounded, !_isListView), // 왼쪽: 그리드
          _buildToggleButton(Icons.format_list_bulleted_rounded, _isListView), // 오른쪽: 리스트
        ],
      ),
    );
  }

  // 10. 개별 탭 버튼 (변동 없음)
  Widget _buildToggleButton(IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          // 클릭된 아이콘이 리스트 아이콘이면 isListView를 true로, 아니면 false(그리드)로 설정
          if (icon == Icons.format_list_bulleted_rounded) {
            _isListView = true;
          } else {
            _isListView = false;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent, // 선택 시 흰색
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            )
          ]
              : [],
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.black87 : Colors.grey[600],
          size: 20,
        ),
      ),
    );
  }

  // 11. 출석 빈도 섹션 (홈 탭 AttendanceStatusCard와 동일)
  Widget _buildAttendanceFrequencySection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          '출석 빈도:',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 8),
        _buildLegendBlock(0.2),
        _buildLegendBlock(0.4),
        _buildLegendBlock(0.6),
        _buildLegendBlock(0.8),
        _buildLegendBlock(1.0),
      ],
    );
  }

  Widget _buildLegendBlock(double intensity) {
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.only(right: 2),
      decoration: BoxDecoration(
        color: _mainOrange.withOpacity(intensity),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  // ⭐ 12. _isListView 상태에 따라 리스트 뷰 또는 그리드 뷰를 반환하는 함수 (위치 이동)
  Widget _buildContentArea() {
    // 모든 멤버 정보 및 더미 데이터 생성
    final List<Map<String, dynamic>> members = [
      {'name': '김학생', 'role': '박사과정', 'percentage': '85 %', 'initial': '김', 'color': _mainOrange, 'records': _generateDummyData(30)},
      {'name': '이연구', 'role': '석사과정', 'percentage': '92 %', 'initial': '이', 'color': _mainOrange, 'records': _generateDummyData(30)},
      {'name': '박조교', 'role': '연구원', 'percentage': '78 %', 'initial': '박', 'color': _mainOrange, 'records': _generateDummyData(30)},
    ];

    if (_isListView) {
      // 3번째 사진: 리스트 뷰
      return ListView(
        children: members.map((member) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: MemberAttendanceCard(
              name: member['name'] as String,
              role: member['role'] as String,
              percentage: member['percentage'] as String,
              initial: member['initial'] as String,
              color: member['color'] as Color,
              allRecords: member['records'] as List<AttendanceRecord>,
            ),
          );
        }).toList(),
      );
    } else {
      // 2번째 사진: 그리드 뷰
      return _buildGridContent(members);
    }
  }

  // ⭐ 13. 그리드 뷰 콘텐츠 위젯 (두 번째 사진의 주간 출석 현황) (위치 이동)
  Widget _buildGridContent(List<Map<String, dynamic>> members) {
    return ListView(
      children: members.map((member) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0), // Padding 간격 조정
          child: Card(
            color: const Color(0xFFFFFFFF),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              // ⭐ 타이틀: 멤버 정보 (리스트와 동일 스타일)
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: (member['color'] as Color).withOpacity(0.2),
                    child: Text(
                      member['initial'] as String,
                      style: TextStyle(color: member['color'] as Color, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(member['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(member['role'] as String, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        member['percentage'] as String,
                        style: TextStyle(
                          color: member['color'] as Color,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '출석률',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),

              // ExpansionTile의 기본 화살표 아이콘을 사용합니다.
              // trailing: const Icon(Icons.keyboard_arrow_down), // ExpansionTile에 이미 내장되어 있음

              // ⭐ Children: 주간 그리드 및 요약 정보
              children: [
                Padding(
                  // 기존의 멤버 정보 Padding은 타이틀로 옮겨졌으므로 children 내부 Padding으로 변경
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 주간 그리드 출석 현황
                      _buildGridAttendanceArea(member),

                      // 그리드 뷰 아래의 총계 요약
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryBox('23일', '총 출석일'),
                            _buildSummaryBox('4일', '연속 출석'),
                            _buildSummaryBox('85 %', '출석률', highlight: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12), // ExpansionTile 닫는 부분과의 간격
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // 2. 주간 그리드 부분을 별도 함수로 분리
  Widget _buildGridAttendanceArea(Map<String, dynamic> member) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // 요일 헤더 (월~일)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const ['월', '화', '수', '목', '금', '토', '일'].map((day) =>
                Expanded(child: Center(child: Text(day, style: TextStyle(fontSize: 12, color: Colors.grey))))
            ).toList(),
          ),
          const SizedBox(height: 8),

          // 주차별 출석 블록
          for (int week = 1; week <= 5; week++) // 5주차까지 표시
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 주차 텍스트
                  SizedBox(
                    width: 30,
                    child: Text('${week}주차', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),

                  // 출석 블록 (7개)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(7, (dayIndex) {
                        final dayOfMonthIndex = dayIndex + (week - 1) * 7;
                        if (dayOfMonthIndex >= 30) {
                          return const SizedBox(width: 20, height: 20);
                        }
                        final record = (member['records'] as List<AttendanceRecord>)[dayOfMonthIndex];
                        final isPresent = record.status == '출석';
                        final blockColor = isPresent ? (member['color'] as Color).withOpacity(0.6) : Colors.grey.shade200;

                        return Container(
                          width: 20, // 작은 사각형 크기
                          height: 20,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: blockColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
                  // 총 시간 표시 (임시)
                  const SizedBox(width: 60, child: Text('72시간', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.right)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 그리드 뷰 아래 요약 박스 헬퍼
  Widget _buildSummaryBox(String value, String label, {bool highlight = false}) {
    return Container(
      width: MediaQuery.of(context).size.width / 4,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: highlight ? _mainOrange : Colors.black87,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class MemberAttendanceCard extends StatefulWidget {
  final String name;
  final String role;
  final String percentage;
  final String initial;
  final Color color;
  final List<AttendanceRecord> allRecords;

  const MemberAttendanceCard({
    super.key,
    required this.name,
    required this.role,
    required this.percentage,
    required this.initial,
    required this.color,
    required this.allRecords,
  });

  @override
  State<MemberAttendanceCard> createState() => _MemberAttendanceCardState();
}

class _MemberAttendanceCardState extends State<MemberAttendanceCard> {
  bool _isSeeMoreClicked = false;
  late List<AttendanceRecord> _recentRecords;

  @override
  void initState() {
    super.initState();
    _recentRecords = widget.allRecords.take(7).toList();
  }

  @override
  Widget build(BuildContext context) {
    final recordsToShow = _isSeeMoreClicked ? widget.allRecords : _recentRecords;

    return Card(
      color: const Color(0xFFFFFFFF),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        onExpansionChanged: (bool isExpanding) {
          if (!isExpanding) {
            setState(() {
              _isSeeMoreClicked = false;
            });
          }
        },
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: widget.color.withOpacity(0.2),
              child: Text(
                widget.initial,
                style: TextStyle(color: widget.color, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(widget.role, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.percentage,
                  style: TextStyle(
                    color: widget.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '출석률',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade500, size: 24),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildHeaderRow(),
          const Divider(),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recordsToShow.length,
            itemBuilder: (context, index) {
              return _buildAttendanceRow(recordsToShow[index]);
            },
            separatorBuilder: (context, index) => const SizedBox(height: 8),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _isSeeMoreClicked = !_isSeeMoreClicked;
              });
            },
            child: Text(
              _isSeeMoreClicked
                  ? '간략히 보기'
                  : '더 보기 (총 ${widget.allRecords.length}일)',
              style: const TextStyle(color: _mainOrange, fontWeight: FontWeight.w500),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    const style = TextStyle(color: Colors.grey, fontSize: 12);
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 3, child: Text('날짜', style: style)),
          Expanded(flex: 2, child: Text('출석 여부', style: style, textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('체크인', style: style, textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('체크아웃', style: style, textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildAttendanceRow(AttendanceRecord record) {
    bool isPresent = record.status == '출석';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(record.date, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPresent ? const Color(0xFFE8F5E9) : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  record.status,
                  style: TextStyle(
                    color: isPresent ? const Color(0xFF2E7D32) : Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              isPresent ? record.checkIn : '-',
              textAlign: TextAlign.center,
              style: TextStyle(color: isPresent ? Colors.black87 : Colors.grey),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              isPresent ? record.checkOut : '-',
              textAlign: TextAlign.center,
              style: TextStyle(color: isPresent ? Colors.black87 : Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------
// 12. 멤버 카드 위젯 (MemberAttendanceCard는 _DailyStatusViewState 밖에 있으므로 수정 불필요)
// -----------------------------------------------------------------
// ... (MemberAttendanceCard 클래스 및 _MemberAttendanceCardState는 그대로 유지)
// 오류 메시지에서 언급된 _generateDummyData 관련 오류는 _DailyStatusViewState 안의
// _generateDummyData 함수를 MemberAttendanceCard 위젯이 직접 호출하지 않고
// DailyStatusView의 build()에서 생성하여 prop으로 전달하므로 해결됩니다.

// (MemberAttendanceCard 클래스부터 코드는 이전과 동일합니다.)
// ... (생략)