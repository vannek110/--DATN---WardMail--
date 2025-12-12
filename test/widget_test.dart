// This is a basic Flutter widget test.
//
// Expanded version with multiple widget tests for demonstration.
// All widgets are self-contained inside this test file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // BASIC TEST FROM USER
  // ---------------------------------------------------------------------------
  testWidgets('App renders a simple test widget', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Test widget')),
      ),
    ));

    expect(find.text('Test widget'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // TEST 2: Verify an Icon is present
  // ---------------------------------------------------------------------------
  testWidgets('Check if an Icon is displayed', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(child: Icon(Icons.star)),
      ),
    ));

    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // TEST 3: Button tap should update counter
  // ---------------------------------------------------------------------------
  testWidgets('Button tap increments counter', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CounterTestWidget(),
    ));

    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); // update UI

    expect(find.text('1'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // TEST 4: TextField input test
  // ---------------------------------------------------------------------------
  testWidgets('Typing in TextField updates displayed text',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TextFieldEchoWidget(),
    ));

    const input = 'Hello World';

    await tester.enterText(find.byType(TextField), input);
    await tester.pump();

    expect(find.text(input), findsNWidgets(2)); // echo appears too
  });

  // ---------------------------------------------------------------------------
  // TEST 5: Navigation Test (push to next screen)
  // ---------------------------------------------------------------------------
  testWidgets('Navigation test: tap to go to second page',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: FirstPage(),
    ));

    expect(find.text('First Page'), findsOneWidget);

    await tester.tap(find.text('Go to Second Page'));
    await tester.pumpAndSettle();

    expect(find.text('Second Page'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // TEST 6: ListView rendering items
  // ---------------------------------------------------------------------------
  testWidgets('ListView renders all items', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ListViewTestWidget(),
    ));

    // Scroll until last item visible
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();

    expect(find.text('Item 19'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // TEST 7: Finder examples
  // ---------------------------------------------------------------------------
  testWidgets('Finder advanced usage', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: const [
            Text('Alpha', key: Key('alphaText')),
            Text('Beta'),
            Icon(Icons.home),
          ],
        ),
      ),
    ));

    expect(find.byKey(const Key('alphaText')), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.byIcon(Icons.home), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // TEST 8: Pump vs PumpAndSettle timing
  // ---------------------------------------------------------------------------
  testWidgets('Pump vs PumpAndSettle animation test',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AnimationTestWidget(),
    ));

    // Start animation
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(find.text('Animating...'), findsOneWidget);

    // Wait until animation finishes
    await tester.pumpAndSettle();

    expect(find.text('Done'), findsOneWidget);
  });
}

// ============================================================================
// BELOW: TEST WIDGETS (Self-contained, no external files needed)
// ============================================================================

// Simple counter widget -------------------------------------------------------
class CounterTestWidget extends StatefulWidget {
  @override
  State<CounterTestWidget> createState() => _CounterTestWidgetState();
}

class _CounterTestWidgetState extends State<CounterTestWidget> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('$count')),
      floatingActionButton: ElevatedButton(
        onPressed: () => setState(() => count++),
        child: const Text('Increment'),
      ),
    );
  }
}

// TextField + Echo widget -----------------------------------------------------
class TextFieldEchoWidget extends StatefulWidget {
  @override
  State<TextFieldEchoWidget> createState() => _TextFieldEchoWidgetState();
}

class _TextFieldEchoWidgetState extends State<TextFieldEchoWidget> {
  String value = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => value = v),
          ),
          Text(value), // echo
        ],
      ),
    );
  }
}

// Navigation test widgets -----------------------------------------------------
class FirstPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          child: const Text('Go to Second Page'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SecondPage()),
            );
          },
        ),
      ),
    );
  }
}

class SecondPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Second Page')),
    );
  }
}

// ListView test widget --------------------------------------------------------
class ListViewTestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: 20,
        itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
      ),
    );
  }
}

// Animation test widget -------------------------------------------------------
class AnimationTestWidget extends StatefulWidget {
  @override
  State<AnimationTestWidget> createState() => _AnimationTestWidgetState();
}

class _AnimationTestWidgetState extends State<AnimationTestWidget>
    with SingleTickerProviderStateMixin {
  bool running = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(running ? 'Animating...' : 'Done'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          setState(() => running = true);
          await Future.delayed(const Duration(milliseconds: 600));
          setState(() => running = false);
        },
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}
