// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('App builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LabAttendanceApp());
    // AuthGate 등 비동기 스트림/애니메이션으로 settle이 끝나지 않을 수 있어
    // 최소 스모크 테스트는 한 프레임만 진행합니다.
    await tester.pump();

    // 최소 스모크 테스트: 앱이 예외 없이 빌드된다.
    expect(find.byType(LabAttendanceApp), findsOneWidget);
  });
}
