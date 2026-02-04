import 'package:flutter/material.dart';

const Color _mainOrange = Color(0xFFF97316);

// ⭐ BottomNavigationBar 위젯을 별도의 StatelessWidget으로 분리
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onItemSelected;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFFFFFFFF),
      selectedItemColor: _mainOrange,
      unselectedItemColor: Colors.grey,
      // 선택 이벤트 핸들러 추가 (탭 전환 로직이 있다면 사용)
      onTap: onItemSelected,
      items: [
        BottomNavigationBarItem(
          icon: Icon(currentIndex == 0 ? Icons.home : Icons.home_outlined),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: Icon(currentIndex == 1 ? Icons.people_alt : Icons.people_alt_outlined),
          label: '모임',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.show_chart),
          label: '잔류현황',
        ),
      ],
      currentIndex: currentIndex,
    );
  }
}