import 'package:castflow/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders CastFlow dashboard', (tester) async {
    await tester.pumpWidget(const CastFlowApp());

    expect(find.text('CastFlow'), findsOneWidget);
    expect(find.text('إرسال الشاشة'), findsOneWidget);
    expect(find.text('استقبال العرض'), findsOneWidget);
  });
}
