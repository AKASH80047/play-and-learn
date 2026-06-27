import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_and_learn/presentation/treehouse/treehouse_screen.dart';

void main() {
  testWidgets('Treehouse screen renders all interactive items and responds to taps', (WidgetTester tester) async {
    // Build PipsTreehouseScreen and trigger a frame.
    await tester.pumpWidget(const MaterialApp(
      home: PipsTreehouseScreen(),
    ));
    await tester.pump();

    // Verify header exists
    expect(find.text('Happiness: 0'), findsOneWidget);

    // Verify initial Pip speech bubble text
    expect(find.text('Hoot! Welcome to my Treehouse! 🏡🌳'), findsOneWidget);

    // Verify hats and buttons exist
    expect(find.text('❌'), findsOneWidget);
    expect(find.text('🤠'), findsOneWidget);
    expect(find.text('🧙‍♂️'), findsOneWidget);
    expect(find.text('👑'), findsOneWidget);

    // Tap the window (which cycles the time of day)
    // Tapping the window wiggles/cycles, and displays a sunset quote
    final windowFinder = find.text('🖼️');
    expect(windowFinder, findsOneWidget);
    await tester.tap(windowFinder);
    await tester.pump(const Duration(milliseconds: 800));

    // Verify time of day cycle speech triggered
    expect(find.text('Wow! Look at the beautiful sunset! 🌇🧡'), findsOneWidget);

    // Tap window again for night
    await tester.tap(windowFinder);
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Time to count the stars! 🌙🌟'), findsOneWidget);

    // Tap Lantern (shows 🔌 initially)
    final lanternFinder = find.text('🔌');
    expect(lanternFinder, findsOneWidget);
    await tester.tap(lanternFinder);
    await tester.pump(const Duration(milliseconds: 800));

    // Verify lantern lights up and shows 💡
    expect(find.text('💡'), findsOneWidget);
    expect(find.text('Ooh, so bright and warm! 💡✨'), findsOneWidget);

    // Tap Radio
    final radioFinder = find.text('📻');
    expect(radioFinder, findsOneWidget);
    await tester.tap(radioFinder);
    await tester.pump(const Duration(milliseconds: 800));
    
    // Verify radio is on and shows active musical symbol
    expect(find.text('⚡'), findsOneWidget);
    expect(find.text('Let\'s groove! Hoot! 🎶🦉'), findsOneWidget);

    // Choose Wizard Hat 🧙‍♂️
    final wizardHatBtn = find.text('🧙‍♂️');
    await tester.tap(wizardHatBtn);
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Alakazam! I can cast spells now! 🧙‍♂️✨'), findsOneWidget);
  });
}
