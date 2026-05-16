import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simplepy_flutter/simplepy_flutter.dart';

void main() {


  testWidgets('pywidget button with on_pressed', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PyWidget("""
x=42

def pressed():
  x=123
  update_node("text", f"x={x}")

def build():
  return Column(children=[
    Button("CLICK", on_pressed = pressed),
    Text(f"x={x}", id="text")
  ])
""", key: ValueKey(1)),
      ),
    ),
  );

    await tester.pumpAndSettle();
    expect(find.text('x=42'), findsOneWidget);
    expect(find.text('x=123'), findsNothing);
    expect(find.text('CLICK'), findsOneWidget);

    await tester.tap(find.text('CLICK'));
    await tester.pumpAndSettle();

    expect(find.text('x=123'), findsOneWidget);
    expect(find.text('x=42'), findsNothing);
  });
    
}
