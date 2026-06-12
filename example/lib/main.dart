import 'package:flutter/material.dart';
import 'package:simplepy_flutter/simplepy_flutter.dart';


void main() {
  runApp(const PyExampleApp());
}

class PyExampleApp extends StatelessWidget {
  const PyExampleApp({super.key});

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
counter = 0

def button():
  global counter
  counter+=1
  update_node("counter", f"Counter =  {counter}")
  
def build():
  return Column(children=[
    Button(text='Increment Counter', onPressed=button),
    Text(f"Counter = {counter}", id="counter",
      style=TextStyle(color=0xff00aaff, fontSize=42))
  ])
""";
    pywidget =  PyWidget(key: key, _ctrl.text);
  }

  void runCode() {
    pywidget = PyWidget(_ctrl.text, key: ValueKey(_ctrl.text.hashCode));
    setState((){});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Simplepy_flutter Example"),
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
