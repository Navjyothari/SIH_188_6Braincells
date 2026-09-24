import 'package:flutter_test/flutter_test.dart';
import 'package:sih/main.dart';

void main() {
  testWidgets('VigilBorderApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VigilBorderApp());
    expect(find.byType(VigilBorderApp), findsOneWidget);
  });
}
