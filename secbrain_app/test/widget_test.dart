import 'package:flutter_test/flutter_test.dart';
import 'package:secbrain_app/main.dart';

void main() {
  testWidgets('SecBrain loads the dashboard', (tester) async {
    await tester.pumpWidget(const SecBrainApp());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Aditya'), findsOneWidget);
    expect(find.text('Today\'s focus'), findsOneWidget);
  });
}
