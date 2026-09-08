import 'package:flutter_test/flutter_test.dart';
import 'package:padel_shuffle/main.dart';

void main() {
  testWidgets('Padel shuffle app splash screen and setup screen test', (WidgetTester tester) async {
    await tester.pumpWidget(const PadelShuffleApp());

    // Verify splash screen displays
    expect(find.text('PADEL SHUFFLE'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    // Tap Skip to immediately advance
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // Verify setup screen is displayed
    expect(find.text('STEP 1 OF 2'), findsOneWidget);
    expect(find.text('Create Tournament'), findsOneWidget);
    expect(find.text('Continue: Add Players'), findsOneWidget);
  });
}
