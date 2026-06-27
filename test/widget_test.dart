import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_and_learn/main.dart';

void main() {
  testWidgets('Dashboard loads and lists activities', (WidgetTester tester) async {
    // Mock SharedPreferences values for test environment
    SharedPreferences.setMockInitialValues({
      'stars': 10,
      'badges': <String>['Balloon Popper 🎈'],
    });

    // Build SproutApp and trigger a frame.
    await tester.pumpWidget(const SproutApp());
    // Render the initial frame without waiting for infinite repeat animation to settle
    await tester.pump();

    // Verify Dashboard displays branding
    expect(find.text('Sprout Land 🌳'), findsOneWidget);
    
    // Verify Level 1 and Level 2 options exist
    expect(find.text('Level 1: Balloon Pop'), findsOneWidget);
    expect(find.text('Level 2: Camera Search'), findsOneWidget);
  });

  testWidgets('Level 3 is locked when stars are below 50', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'stars': 40,
    });

    await tester.pumpWidget(const SproutApp());
    await tester.pump();

    expect(find.text('Requires 50 Stars to open!'), findsOneWidget);
    expect(find.text('Welcome back to the treehouse! 🏡🌳'), findsNothing);
  });

  testWidgets('Level 3 is unlocked when stars are 50 or more', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'stars': 55,
    });

    await tester.pumpWidget(const SproutApp());
    await tester.pump();

    expect(find.text('Welcome back to the treehouse! 🏡🌳'), findsOneWidget);
    expect(find.text('Requires 50 Stars to open!'), findsNothing);
  });
}
