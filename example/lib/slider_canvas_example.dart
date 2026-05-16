import 'package:flutter/material.dart';
import 'package:simplepy_flutter/simplepy_flutter.dart';


void main() {
  runApp(const PyFlutterExampleApp());
}

class PyFlutterExampleApp extends StatelessWidget {
  const PyFlutterExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ExampleScreen(),
    );
  }
}

class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  final key = GlobalKey<PyWidgetState>();
  PyWidget? pywidget;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl.text = """
def slider1(x):
  slider(1,x)

def slider2(x):
  slider(2,x)

def slider(nr, x):
  update_node("text", f"Slider{nr} = {x}")
  clear("c")
  setColor("c", 0xff222222)
  setStyle("c", "fill")
  drawRect("c", 0,0,100,100)
  setColor("c", 0xff00ff00)
  setStyle("c", "fill")
  pi=3.1416
  drawArc("c",50,50, 45, 45,0, -(x-5)/5*2*pi, True)
  update_node(f"sl{3-nr}", 10-x)
    
def build():
  return Column(children=[
    Text("", id="text"),
    Slider(id="sl1", min=0, max=5, value=2.5, divisions=50, on_changed=slider1),
    Slider(id="sl2", min=5, max=10, value=7.5, on_changed=slider2),
    CustomPaint(id="c", width = 100, height = 100, paint=None)
  ])
""";

    pywidget =  PyWidget(key: key, _ctrl.text);
  }

  void runCode() {
    pywidget = PyWidget(_ctrl.text);
    setState((){});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("simplepy_flutter Example"),
      ),
      body: Row(
        children: [
          Expanded(
            flex:1,
            child: Column(children: [
              IconButton(onPressed: runCode, icon: Icon(Icons.play_circle, color: Colors.green)),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  maxLines: null,
                            ),
              )]),
          ),
          Expanded(
            flex: 1,
            child: pywidget!,
          ),
        ],
      ),
    );
  }
}