A Flutter package that allows you to build UI dynamically using Python code.

It connects the **SimplePy runtime** with Flutter and translates Python-defined widget trees into native Flutter widgets.

## Features

- Build Flutter UI using Python code
- Dynamic widget tree updates at runtime
- Support for common Flutter widgets (Text, Column, Row, Container, SizedBox, GridView, Stack, Positioned etc.)
- Canvas drawing API from Python (CustomPaint widget)
- Interactive widgets (Slider, TextField, Button, Image[from url], ...)

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  simplepy:
    version: ^2.0.0

  simplepy_flutter:
    version: ^0.0.1
```

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:simplepy_flutter/simplepy_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: PyWidget("""
def button_pressed():
  update_node("text_widget", "Button pressed!")

def build():
    return Column(children=[
        Text("Hello from Python", id="text_widget"),
        Button(text="Click me", on_pressed=button_pressed)
    ])
"""),
    );
  }
}
```