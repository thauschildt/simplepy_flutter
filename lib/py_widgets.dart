import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simplepy/simplepy.dart';
import 'py_painter.dart';

/// A Flutter widget that renders UI defined by Python code.
///
/// `PyWidget` acts as a bridge between the SimplePy runtime and Flutter.
/// It takes Python code as input, executes it using a `simplepy` interpreter,
/// and dynamically converts the resulting widget tree into Flutter widgets.
///
/// The Python code is expected to define a `build()` function that returns
/// a widget structure understood by the SimplePy Flutter bridge.
///
/// Example:
/// ```python
/// def build():
///     return Column(children=[
///         Text("Hello"),
///         Button(text="Click me")
///     ])
/// ```
///
/// The widget tree is rebuilt whenever the Python runtime updates the state.
class PyWidget extends StatefulWidget {
  final String code;
  final Interpreter? interpreter;
  const PyWidget(this.code, {super.key, this.interpreter});
  
  @override
  State<PyWidget> createState() => PyWidgetState();
}

/// Internal state of [PyWidget].
///
/// Responsible for:
/// - Initializing and managing the SimplePy interpreter
/// - Loading the Python widget classes and user code
/// - Translating Python AST output into Flutter widgets
/// - Handling updates from Python runtime (state + UI updates)
/// - Managing widget controllers (e.g. sliders, canvas, text fields)
class PyWidgetState extends State<PyWidget> {
  late String? _preamble;
  bool _ready = false;
  late Interpreter _interpreter;
  Widget? _tree;
  Map<String, dynamic> _dict={};
  final Map<int, PyCanvasController> _canvasControllers={};
  final Map<int, TextEditingController> _textControllers={};
  final Map<int, dynamic> _widgetValues = {};
  final Map<int, ValueNotifier> _notifiers = {};
  final Map<int, Widget> _widgets = {};
  Map<String, int> user2id = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    for (final n in _notifiers.values) {
      n.dispose();
    }
    super.dispose();
  }

  Future<void> _init() async {
    _interpreter = widget.interpreter ?? Interpreter();
    await loadPyCode();
    registerCommands();
    _interpreter.registerFunction("getValue", (args, kwargs) {
      String userid = args[0];
      int? id = user2id[userid];
      if (id==null) return;
      var val = _widgetValues[id];
      if (_notifiers[id]!=null) val = _notifiers[id]!.value;
      if (val is String || val == null) return val;
      if (val is int) return PyNum.int(val);
      if (val is double) return PyNum.double(val);
      return null;
    });
  }

  void registerCommands() {
    _interpreter.registerFunction("clear", (args, kwargs) {
      int? id = user2id[args[0]];
      if (id==null) return;
      _canvasControllers[id]?.clear();
    });

    _interpreter.registerFunction("drawArc", (args, kwargs) {
      int? id = user2id[args[0]];
      if (id==null) return;
      double x=args[1].toDouble();
      double y=args[2].toDouble();
      double rx=args[3].toDouble();
      double ry=args[4].toDouble();
      double a0=args[5].toDouble();
      double a1=args[6].toDouble();
      bool sector=false;
      if (args.length>7) sector = args[7];
      _canvasControllers[id]?.addCommand((canvas, size, paint) {
        canvas.drawArc(Rect.fromLTRB(x-rx,y-ry,x+rx,y+ry), a0, a1, sector, paint);
      });
    });

    _interpreter.registerFunction("drawCircle", (args, kwargs) {
      int? id = user2id[args[0]];
      if (id==null) return;
      double x=args[1].toDouble();
      double y=args[2].toDouble();
      double r=args[3].toDouble();
      _canvasControllers[id]?.addCommand((canvas, size, paint) {
        canvas.drawCircle(Offset(x,y), r, paint);
      });
    });
    _interpreter.registerFunction("drawLine", (args, kwargs) {
      int? id = user2id[args[0]];
      if (id==null) return;
      double x1=args[1].toDouble();
      double y1=args[2].toDouble();
      double x2=args[3].toDouble();
      double y2=args[4].toDouble();
      _canvasControllers[id]?.addCommand((canvas, size, paint) {
        canvas.drawLine(Offset(x1,y1), Offset(x2,y2), paint);
      });
    });
    _interpreter.registerFunction("drawRect", (args, kwargs) {
      int? id = user2id[args[0]];
      if (id==null) return;
      double x=args[1].toDouble();
      double y=args[2].toDouble();
      double w=args[3].toDouble();
      double h=args[4].toDouble();
      _canvasControllers[id]?.addCommand((Canvas canvas, Size size, Paint paint) {
        canvas.drawRect(Rect.fromLTWH(x,y,w,h), paint);
      });
    });
    _interpreter.registerFunction("drawText", (args, kwargs) {
      int? id = user2id[args[0]];
      if (id==null) return;
      double x=args[1].toDouble();
      double y=args[2].toDouble();
      String text = args[3];
      _canvasControllers[id]?.addCommand((Canvas canvas, Size size, Paint paint) {
        final textStyle = TextStyle(
          color: Colors.black,
          fontSize: 12,
        );
        final textSpan = TextSpan(
          text: text,
          style: textStyle,
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        final offset = Offset(x, y);
        textPainter.paint(canvas, offset);
      });
    });
    _interpreter.registerFunction("setColor", (args, kwargs) {
      int? id = user2id[args[0]];
      if (id==null) return;
      int intCol = args[1].intValue.toInt();
      if (intCol<=0xffffff) intCol += 0xff000000;
      final color = Color(intCol);
      final controller = _canvasControllers[id];
      controller?.setColor(color);
    });
    _interpreter.registerFunction("setStrokeWidth", (args, kwargs) {
      int? id = user2id[args[0]];
      if (id==null) return;
      double width = args[1].toDouble();
      final controller = _canvasControllers[id];
      controller?.setStrokeWidth(width);
    });
    _interpreter.registerFunction("setStyle", (args, kwargs) {
      int? id = user2id[args[0]];
      if (id==null) return;
      String style = args[1];
      final controller = _canvasControllers[id];
      if (style == "stroke") {
        controller?.setStyle(PaintingStyle.stroke);
      } else if (style == "fill") {
        controller?.setStyle(PaintingStyle.fill);
      }
    });
  }

  Map<String, dynamic>? _findInDict(Map<String, dynamic> dict, int id) {
    if (dict["id"].intValue.toInt()==id) {
      return dict;
    }
    if (dict["kwargs"]["children"]!=null) {
      for (int i=0; i<dict["kwargs"]["children"].length; i++) {
        Map<String, dynamic> c = dict["kwargs"]["children"][i];
        Map<String, dynamic>? result = _findInDict(c, id);
        if (result!=null) return result;
      }
    } else if (dict["kwargs"]["child"]!=null) {
      return _findInDict(dict["kwargs"]["child"], id);
    }
    return null;
  }

  void replaceNode(List<dynamic> args, Map<dynamic, dynamic> kwargs) {
    final userid=args[0];
    final id = userid=="" ? -1 : user2id[userid];
    if (id==null) return;
    //_interpreter.globals.define("tmp", args[1]);
    var widget = _castMap(_interpreter.interpret(
        Parser(Lexer("tmp=${args[1]}\ntmp.to_dict()").scanTokens()).parse(),
        null,
        (err) => {}
      ));
    if (_replace(_dict, id, widget)) {
      debugPrint("replace root");
      _dict = widget;
    }
    user2id[userid]=widget["id"].intValue.toInt();
    _tree = fromDict(_dict, {});
    setState(() {});
  }

  bool _replace(Map<String, dynamic> dict, int id, Map<String, dynamic> widget) {
    //if (dict["kwargs"]["userid"]!=null)
    //  print("check $id ${dict["id"]} ${dict["type"]} ${dict["kwargs"]["userid"]}");
    if (id<0 || dict["id"].intValue.toInt()==id) {
      return true;
    } else if (dict["kwargs"]["children"]!=null) {
      for (int i=0; i<dict["kwargs"]["children"].length; i++) {
        Map<String, dynamic> c = dict["kwargs"]["children"][i];
        if (_replace(c, id, widget)) {
          dict["kwargs"]["children"][i]=widget;
          break;
        }
      }
    } else if (dict["kwargs"]["child"]!=null) {
      if (_replace(dict["kwargs"]["child"], id, widget)) {
        dict["kwargs"]["child"]=widget;
      }
    }
    return false;
  }

  /// update property of a widget specified by id and rebuild widget tree
  void setValue(List<dynamic> args, Map<dynamic, dynamic> kwargs) {
    final userid=args[0];
    final id = user2id[userid];
    if (id==null) return;
    _update(_dict, id, args[1]);
    _tree = fromDict(_dict, {});
    setState(() {});
  }

  /// recursively search for id and update its property
  void _update(Map<String, dynamic> dict, int id, dynamic arg2) {
    if (dict["id"].intValue.toInt()==id) {
      if (dict["type"]=="Text") {
        dict["kwargs"]["data"] = arg2;
      } else if (dict["type"]=="DropdownButton") {
        _notifiers[id]!.value = arg2.toDouble();
      } else if (dict["type"]=="Slider") {
        dict["kwargs"]["value"] = arg2;
        dict["kwargs"]["label"] = "$arg2";
        _notifiers[id]!.value = arg2.toDouble();
      } else if (["Checkbox", "Switch"].contains(dict["type"])) {
        _notifiers[id]!.value = arg2;
      }
    } else if (dict["kwargs"]["children"]!=null) {
      for (Map<String, dynamic> c in dict["kwargs"]["children"]) {
        _update(c, id, arg2);
      }
    } else if (dict["kwargs"]["child"]!=null) {
      _update(dict["kwargs"]["child"], id, arg2);
    }
  }

  void runBuild() {
    try {
      String error="";
      _dict = _castMap(_interpreter.interpret(
        Parser(Lexer("build().to_dict()").scanTokens()).parse(),
        null,
        (err) => error+="$err\n"
      ));
      if (error!="") {
        _tree=Text(error, style: TextStyle(color: Colors.red));
      } else {
        _tree = fromDict(_dict, {});
        setState(() { },);
      }
    } catch(e) {
      _tree = Text("$e", style: TextStyle(color: Colors.red));
    }
  }

  Future<void> loadPyCode() async {
    if (!_ready) {
      _preamble = await rootBundle.loadString(
        'packages/simplepy_flutter/assets/python/py_widgets.py',
      );
    }
    _interpreter.registerFunction("update_node", setValue);
    _interpreter.registerFunction("replace_node", replaceNode);
    _interpreter.registerFunction("update_all", (args, kwargs) {
      runBuild();
      setState(() {});
    });
    final tokens = Lexer(_preamble!).scanTokens();
    final stmts = Parser(tokens).parse();
    _interpreter.interpret(stmts);
    _interpreter.interpret(Parser(Lexer(widget.code).scanTokens()).parse());
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      for (var k in _widgets.keys) {
        if (_widgets[k] is Slider) {
          (_widgets[k] as Slider).onChanged!(_notifiers[k]!.value);
        }
      }
    });
    runBuild();
    setState(() { _ready = true; });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return CircularProgressIndicator();
    return _tree ?? CircularProgressIndicator();
  }

  TextStyle getTextStyle(Map<String, dynamic> kwargs) {
    var color=kwargs['kwargs']['color']?.intValue?.toInt() ?? 0xff000000;
    return TextStyle(color: Color(color), fontSize: 24.0, fontWeight: FontWeight.bold);
  }

  /// Convert serialized widget to flutter Widget
  Widget? fromDict(Map<String, dynamic>? map, Map<String, Function> callbacks) {
    if (map==null) return null;
  final type = map['type'] as String;
  final kwargs = map['kwargs'] as Map<String, dynamic>;
  final id = map['id'].intValue.toInt();
  final userid = kwargs['userid'];
  if (userid!=null) user2id[userid] = id;
  
  try {
  switch (type) {
    case 'Button':
      PyFunction? callback = kwargs['onPressed'] as PyFunction?;
      return ElevatedButton(
        onPressed: callback!=null ? () => callback.call(_interpreter, [], {}) : null,
        child: Text(kwargs['text'] as String),
      );

    case 'Card':
      return Card(
        elevation: kwargs["elevation"]?.toDouble(),
        color: kwargs['color']!=null ? Color((kwargs['color'] as PyNum).intValue!.toInt()) : null,
        shadowColor: kwargs['shadowColor']!=null ? Color((kwargs['shadowColor'] as PyNum).intValue!.toInt()) : null,
        child: fromDict(kwargs['child'], {}),
      );

    case 'Center':
      return Center(
        child: fromDict(kwargs['child'], {}),
      );

    case 'Checkbox':
      if (_notifiers[id]==null) {
        _notifiers[id] = ValueNotifier(kwargs['value'] || false);
      }
      PyFunction? callback = kwargs['onChanged'] as PyFunction?;
      return ValueListenableBuilder(
        valueListenable: _notifiers[id]!,
        builder:(context, value, child) {
          _widgets[id] = Checkbox(
            onChanged: (bool? val) {
              callback?.call(_interpreter, [val], {});
              _notifiers[id]!.value = val;
            },
            value: value,
          );
          return _widgets[id]!;
        }
      );

    case 'ClipRect':
      final child = fromDict(kwargs['child'], {});
      return ClipRect(child: child);

    case 'Column':
      return Column(
        mainAxisAlignment: _parseMainAxisAlignment(kwargs['mainAxisAlignment']),
        crossAxisAlignment: _parseCrossAxisAlignment(kwargs['crossAxisAlignment']),
        children: _buildChildren(kwargs['children'], callbacks),
      );

    case 'Container':
      final child = fromDict(kwargs['child'], {});
      return Container(
        color: Color((kwargs['color'] as PyNum?)?.intValue?.toInt() ?? 0x00000000),
        child: child,
      );

    case 'CustomPaint':
      final child = kwargs['child']!=null ? fromDict(kwargs['child'], {}) : null;
      _canvasControllers[id] ??= PyCanvasController(
        () => (kwargs['paint'] as PyFunction).call(_interpreter,[],{}));
      final width = kwargs['width'].toDouble();
      final height = kwargs['height'].toDouble();
      return CustomPaint(
        size: Size(width, height),
        painter: PyPainter(_canvasControllers[id]!),
        child: child,
      );

    case 'Divider':
      return Divider(
        height: kwargs['height']?.toDouble(),
        color: kwargs['color']!=null ?  Color((kwargs['color'] as PyNum).intValue!.toInt()) : null,
        indent: kwargs['indent']?.toDouble(),
        endIndent: kwargs['endIndent']?.toDouble(),
        thickness: kwargs['thickness']?.toDouble(),
      );

    case 'DropdownButton':
      PyFunction? onChanged = kwargs['onChanged'];
      if (_notifiers[id]==null) {
        _notifiers[id] = ValueNotifier(kwargs['value'].toDouble());
      }
      return ValueListenableBuilder(
        valueListenable: _notifiers[id]!,
        builder:(context, value, child) {
          return DropdownButton<double>(
            value: value,
            items: _buildMenu(kwargs['items'], callbacks),
            onChanged: onChanged!=null? (val) {
              _notifiers[id]!.value = val;
              onChanged.call(_interpreter, [val], {});
            } : null,
          );
        });

    case 'DropdownMenuItem':
      return DropdownMenuItem<double>(
        value: kwargs['value']?.toDouble(),
        child: fromDict(kwargs['child'], {}) ?? Placeholder()
        );

    case 'Expanded':
      final child = fromDict(kwargs['child'], {});
      final flex = kwargs['flex']?.toInt() ?? 1;
      return Expanded(
        flex: flex,
        child: child!,
      );

    case 'Flexible':
      final child = fromDict(kwargs['child'], {});
      final flex = kwargs['flex']?.intValue!.toInt() ?? 1;
      final fit = kwargs['fit'];
      return Flexible(
        flex: flex,
        fit: fit=="tight" ? FlexFit.tight : FlexFit.loose,
        child: child!,
      );

    case 'GridView':
      final count = kwargs['count'].intValue.toInt();
      return GridView.count(
        crossAxisCount: count,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
        children: _buildChildren(kwargs['children'], callbacks),
      );

    case 'Image':
      if (kwargs["url"] != null) {
        var w = Image.network(kwargs['url'],
          width: kwargs['width']?.toDouble(),
          height: kwargs['height']?.toDouble(),
          scale: kwargs['scale']?.toDouble() ?? 1.0,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image);
          },
        );
        return w;
      }
      if (kwargs["base64"] != null) {
        return Image.memory(base64Decode(kwargs['base64']),
          width: kwargs['width']?.toDouble(),
          height: kwargs['height']?.toDouble(),
          scale: kwargs['scale']?.toDouble() ?? 1.0,
        );
      }
      return Placeholder();

    case 'Icon':
      return Icon(IconData(
        kwargs['codepoint']?.intValue.toInt(),
        fontFamily: kwargs['fontFamily'] ?? "MaterialIcons",
      ));

    case 'InkWell':
      PyFunction? onTap = kwargs['onTap'];
      return InkWell(
        onTap: onTap!=null? () => onTap.call(_interpreter, [], {}) : null,
        child: fromDict(kwargs["child"], callbacks)
      );

    case 'Listener':
      PyFunction? down = kwargs['onPointerDown'];
      PyFunction? up = kwargs['onPointerUp'];
      PyFunction? move = kwargs['onPointerMove'];
      PyFunction? hover = kwargs['onPointerHover'];
      return Listener(
        onPointerDown: down!=null? (PointerDownEvent evt)
          => down.call(_interpreter, [PyNum.double(evt.localPosition.dx), PyNum.double(evt.localPosition.dy), PyNum.int(evt.buttons)], {}) : null,
        onPointerUp: up!=null? (PointerUpEvent evt)
          => up.call(_interpreter, [PyNum.double(evt.localPosition.dx), PyNum.double(evt.localPosition.dy)], {}) : null,
        onPointerMove: move!=null? (PointerMoveEvent evt)
          => move.call(_interpreter, [PyNum.double(evt.localPosition.dx), PyNum.double(evt.localPosition.dy)], {}) : null,
        onPointerHover: hover!=null? (PointerHoverEvent evt)
          => hover.call(_interpreter, [PyNum.double(evt.localPosition.dx), PyNum.double(evt.localPosition.dy)], {}) : null,
        child: fromDict(kwargs["child"], callbacks)
      );

    case 'ListTile':
      PyFunction? onTap =  kwargs['onTap'] as PyFunction?;
      PyFunction? onLongPress =  kwargs['onLongPress'] as PyFunction?;
      Color? textcolor, tilecolor, iconcolor;
      if (kwargs['textColor']!=null) textcolor = Color((kwargs['textColor'] as PyNum).intValue!.toInt());
      if (kwargs['iconColor']!=null) iconcolor = Color((kwargs['iconColor'] as PyNum).intValue!.toInt());
      if (kwargs['tileColor']!=null) tilecolor = Color((kwargs['tileColor'] as PyNum).intValue!.toInt());
      return ListTile(
        onTap: onTap!=null ? () => onTap.call(_interpreter, [], {}) : null,
        onLongPress: onLongPress!=null ? () => onLongPress.call(_interpreter, [], {}) : null,
        contentPadding: EdgeInsets.all(4),
        leading: kwargs['leading']!=null ? fromDict(kwargs['leading'], {}) : null,
        trailing: kwargs['trailing']!=null ? fromDict(kwargs['trailing'], {}) : null,
        title: kwargs['title']!=null ? fromDict(kwargs['title'], {}) : null,
        subtitle: kwargs['subtitle']!=null ? fromDict(kwargs['subtitle'], {}) : null,
        textColor: textcolor,
        iconColor: iconcolor,
        tileColor: tilecolor,
      );

    case 'ListView':
      return ListView(children: _buildChildren(kwargs['children'], callbacks));

    case 'Padding':
      return Padding(
        padding: EdgeInsets.all(kwargs['padding'].toDouble()),
        child: fromDict(kwargs['child'], callbacks),
      );

    case 'Positioned':
      return Positioned(
        left: (kwargs['left']?.toDouble()),
        top: (kwargs['top']?.toDouble()),
        right: (kwargs['right']?.toDouble()),
        bottom: (kwargs['bottom']?.toDouble()),
        width: (kwargs['width']?.toDouble()),
        height: (kwargs['height']?.toDouble()),
        child: fromDict(kwargs['child'], callbacks)!,
      );

    case 'Row':
      return Row(
        mainAxisAlignment: _parseMainAxisAlignment(kwargs['mainAxisAlignment']),
        crossAxisAlignment: _parseCrossAxisAlignment(kwargs['crossAxisAlignment']),
        children: _buildChildren(kwargs['children'], callbacks),
      );

    case 'SingleChildScrollView':
      final child = fromDict(kwargs['child'], {});
      return SingleChildScrollView(
        child: child,
      );

    case 'SizedBox':
      final child = fromDict(kwargs['child'], {});
      var width = kwargs['width'];
      var height = kwargs['height'];
      if (width!=null) width = (width as PyNum).toDouble();
      if (height!=null) height = (height as PyNum).toDouble();
      return SizedBox(
        width: width,
        height: height,
        child: child,
      );

    case 'Slider':
      PyFunction? callback = kwargs['onChanged'] as PyFunction?;
      if (_notifiers[id]==null) {
        _notifiers[id] = ValueNotifier(kwargs['value'].toDouble());
      }
      return ValueListenableBuilder(
        valueListenable: _notifiers[id]!,
        builder:(context, value, child) {
          var d = _findInDict(_dict, id);
          var kwargs = d!["kwargs"];
          _widgets[id] = Slider(
            min: kwargs['min'].toDouble() ?? 0.0,
            max: kwargs['max'].toDouble() ?? 1.0,
            value: value,
            label: kwargs['label'],
            divisions: kwargs['divisions']?.intValue.toInt(),
            onChanged: (val) {
              callback?.call(_interpreter, [PyNum.double(val)], {});
              kwargs["label"]="${(val.toDouble()*1e6).round()/1e6}";
              _notifiers[id]!.value = val;
            }
          );
          return _widgets[id]!;}
      );  

    case 'Stack':
      final children = _buildChildren(kwargs['children'], callbacks);
      final alignment = _parseAlignment(kwargs['alignment']);
      return Stack(
        alignment: alignment,
        children: children,
      );

    case 'Switch':
      if (_notifiers[id]==null) {
        _notifiers[id] = ValueNotifier(kwargs['value'] || false);
      }
      PyFunction? callback = kwargs['onChanged'] as PyFunction?;
      return ValueListenableBuilder(
        valueListenable: _notifiers[id]!,
        builder:(context, value, child) {
          _widgets[id] = Switch(
            onChanged: (bool? val) {
              callback?.call(_interpreter, [val], {});
              _notifiers[id]!.value = val;
            },
            value: value,
          );
          return _widgets[id]!;
        }
      );

    case 'Text':
      var style = kwargs['style'];
      if (style!=null) style = getTextStyle(kwargs['style']);
      return Text(kwargs['data'] as String, style: style);

    case 'TextField':
      _textControllers[id] = TextEditingController(text: kwargs['data'] as String);
      int? rows = kwargs["rows"].intValue.toInt();
      return TextField(minLines: rows, maxLines: null, controller: _textControllers[id]);

    case 'Tooltip':
        final child = fromDict(kwargs['child'], {});
        return Tooltip(
          message: kwargs['message'],
          child: child,
        );

    case 'Wrap':
        return Wrap(
          children: _buildChildren(kwargs['children'], callbacks),
        );

    default:
      return const SizedBox();
  }
  } catch(e) {
    return Text("Error creating $type ($kwargs):\n$e", style: TextStyle(color: Colors.red));
  }

}

  List<Widget> _buildChildren(dynamic children, Map<String, Function> callbacks) {
    if (children == null) return [];
    return (children as List)
        .map((c) => fromDict(_castMap(c), callbacks)!)
        .toList();
  }

  List<DropdownMenuItem<double>> _buildMenu(dynamic items, Map<String, Function> callbacks) {
    if (items == null) return [];
    return (items as List)
        .map((c) => fromDict(_castMap(c), callbacks)!)
        .toList().cast<DropdownMenuItem<double>>();
  }

}

/// Converts a nested interpreter object structure into a Dart Map.
///
/// The SimplePy interpreter returns nested objects (PyList, PyNum, maps),
/// which must be converted into native Dart types before widget rendering.
///
/// This function recursively normalizes:
/// - `PyList` → `List<dynamic>`
/// - `Map<Object?, Object?>` → `Map<String, dynamic>`
Map<String, dynamic> _castMap(Object? value) {
  if (value == null) return {};
  final map = value as Map<Object?, Object?>;
  return map.map((k, v) {
    if (v is Map<Object?, Object?>) {
      return MapEntry(k.toString(), _castMap(v));
    } else if (v is PyList) {
      return MapEntry(k.toString(), _castList(v.list));
    } else {
      return MapEntry(k.toString(), v);
    }
  });
}

/// Recursively converts interpreter list structures into Dart Lists.
///
/// Handles nested lists and map structures produced by the SimplePy runtime.
List<dynamic> _castList(List value) {
  return value.map((e) {
    if (e is Map<Object?, Object?>) return _castMap(e);
    if (e is List) return _castList(e);
    return e;
  }).toList();
}

/// Converts Python string values into Flutter MainAxisAlignment.
MainAxisAlignment _parseMainAxisAlignment(dynamic value) {
  switch (value) {
    case 'center':        return MainAxisAlignment.center;
    case 'end':           return MainAxisAlignment.end;
    case 'spaceBetween':  return MainAxisAlignment.spaceBetween;
    case 'spaceAround':   return MainAxisAlignment.spaceAround;
    case 'spaceEvenly':   return MainAxisAlignment.spaceEvenly;
    default:              return MainAxisAlignment.start;
  }
}

/// Converts Python string values into Flutter Alignment.
Alignment _parseAlignment(dynamic value) {
  switch (value) {
    case 'center':        return Alignment.center;
    case 'centerLeft':    return Alignment.centerLeft;
    case 'centerRight':   return Alignment.centerRight;
    case 'bottomCenter':  return Alignment.bottomCenter;
    case 'bottomLeft':    return Alignment.bottomLeft;
    case 'bottomRight':   return Alignment.bottomRight;
    case 'topCenter':     return Alignment.topCenter;
    case 'topLeft':       return Alignment.topLeft;
    case 'topRight':      return Alignment.topRight;
    default:              return Alignment.topLeft;
  }
}

/// Converts Python string values into Flutter CrossAxisAlignment.
CrossAxisAlignment _parseCrossAxisAlignment(dynamic value) {
  switch (value) {
    case 'start':    return CrossAxisAlignment.start;
    case 'end':      return CrossAxisAlignment.end;
    case 'stretch':  return CrossAxisAlignment.stretch;
    case 'baseline': return CrossAxisAlignment.baseline;
    default:         return CrossAxisAlignment.center;
  }
}