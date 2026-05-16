import 'package:flutter/material.dart';

/// Controls drawing operations for a Python-driven CustomPaint widget.
///
/// This class collects drawing commands issued from Python code and
/// replays them during Flutter's paint phase.
///
/// Each command stores a snapshot of the current paint configuration
/// (color, stroke width, style) at the time it was issued.
class PyCanvasController extends ChangeNotifier {
  final List<Function(Canvas, Size)> _commands = [];
  final Function pypaint;

  Paint currentPaint = Paint()
    ..color = Colors.black
    ..strokeWidth = 1
    ..style = PaintingStyle.fill;

  PyCanvasController(this.pypaint);
  
  void setColor(Color color) {
    currentPaint.color = color;
  }

  void setStrokeWidth(double width) {
    currentPaint.strokeWidth = width;
  }

  void setStyle(PaintingStyle style) {
    currentPaint.style = style;
  }

  void addCommand(void Function(Canvas, Size, Paint) drawCommand) {
    final paintCopy = Paint()
      ..color = currentPaint.color
      ..strokeWidth = currentPaint.strokeWidth
      ..style = currentPaint.style;
    _commands.add((canvas, size) {
      drawCommand(canvas, size, paintCopy);
    });
    notifyListeners();
  }

  void clear() {
    _commands.clear();
    notifyListeners();
  }

  void paint(Canvas canvas, Size size) {
    for (final command in _commands) {
      command(canvas, size);
    }
  }
}

/// CustomPainter that renders drawing commands from a [PyCanvasController].
///
/// It listens to the controller and repaints whenever new drawing commands
/// are added or the canvas is cleared.
class PyPainter extends CustomPainter {

  final PyCanvasController controller;

  PyPainter(this.controller) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    controller.paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant PyPainter oldDelegate) => oldDelegate.controller != controller;
}