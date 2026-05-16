"""
SimplePy Flutter Widget Classes

This module defines the core widget classes used by the SimplePy Flutter bridge.

It provides a Python-side widget API that mirrors a subset of Flutter's widget
tree structure. Each widget can be converted into a serializable dictionary
using `to_dict()`, which is then interpreted by the Flutter runtime to build
the actual UI.

Key concepts:
- Widgets are represented as Python objects
- Each widget has a unique internal `id`
- The widget tree is converted into a JSON-like structure via `to_dict()`
- Flutter reconstructs the UI from this structure
- Callbacks (e.g. button presses, sliders) are passed through the interpreter

This module is loaded automatically by the Flutter package and serves as the
base environment for user-defined Python UI code.

Currently supported widgets include:
- Layout: Column, Row, GridView, Stack, Center, SizedBox, Positioned, ScrollView
- Input: TextField, Slider, Button
- Display: Text, Image, RichText
- Interaction: Listener
- Graphics: CustomPaint
- Misc: Container, ClipRect
"""

_id_counter = 0

def next_id():
    global _id_counter
    i = _id_counter
    _id_counter += 1
    return i

class Widget:
    #_id_counter = 0
    def __init__(self, userid=None):
        self.id = next_id()
        self.userid = userid
 
    def to_dict(self):
        raise NotImplementedError

# Button
class Button(Widget):
    def __init__(self, text, on_pressed=None, id=None):
        super().__init__(id)
        self.text = text
        self.on_pressed = on_pressed

    def to_dict(self):
        return {
            "type": "Button",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "text": self.text,
                "on_pressed": self.on_pressed
            }
        }

# Center
class Center(Widget):
    def __init__(self, child, id=None):
        super().__init__(id)
        self.child = child

    def to_dict(self):
        return {
            "type": "Center",
            "id": self.id,
            "kwargs": {
                "child": self.child.to_dict()
            }
        }

# ClipRect
class ClipRect(Widget):
    def __init__(self, child, id=None):
        super().__init__(id)
        self.child = child

    def to_dict(self):
        return {
            "type": "ClipRect",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "child": self.child.to_dict()
            }
        }

# Column
class Column(Widget):
    def __init__(self, children=None, id=None):
        super().__init__(id)
        self.children = children or []

    def to_dict(self):
        return {
            "type": "Column",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "children": [c.to_dict() for c in self.children]
            }
        }
    
# Container
class Container(Widget):
    def __init__(self, child=None, width=None, height=None, color=None, padding=None, id=None):
        super().__init__(id)
        self.child = child
        self.width = width
        self.height = height
        self.color = color
        self.padding = padding

    def to_dict(self):
        c=None
        if self.child: c=self.child.to_dict()
        return {
            "type": "Container",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "child": c,
                "width": self.width,
                "height": self.height,
                "color": self.color,
                "padding": self.padding
            }
        }
    
# CustomPaint
class CustomPaint(Widget):
    def __init__(self, id="canvas", width=200, height=200, child=None, paint=None):
        super().__init__(id)
        self.child = child
        self.paint = paint
        self.width = width
        self.height = height

    def to_dict(self):
        c = None
        if self.child!=None: c = self.child.to_dict()
        return {
            "type": "CustomPaint",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "child": c,
                "paint": self.paint,
                "width": self.width,
                "height": self.height
            }
        }

# GridView
class GridView(Widget):
    def __init__(self, children, count, id=None):
        super().__init__(id)
        self.children = children or []
        self.count = count

    def to_dict(self):
        return {
            "type": "GridView",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "children": [c.to_dict() for c in self.children],
                "count": self.count
            }
        }


# Image
class Image(Widget):
    def __init__(self, url, id=None, width=None, height=None, opacity=None, scale=None):
        super().__init__(id)
        self.url=url
        self.scale=scale
        self.width=width
        self.height=height
        self.opacity=opacity

    def to_dict(self):
        return {
            "type": "Image",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "url": self.url,
                "width": self.width,
                "height": self.height,
                "scale": self.scale,
                "opacity": self.opacity
            }
        }

# Listener
class Listener(Widget):
    def __init__(self, child, onPointerDown=None, onPointerUp=None, onPointerMove=None,
                 onPointerHover=None, id=None):
        super().__init__(id)
        self.child = child
        self.onPointerDown = onPointerDown
        self.onPointerUp = onPointerUp
        self.onPointerMove = onPointerMove
        self.onPointerHover = onPointerHover

    def to_dict(self):
        return {
            "type": "Listener",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "child": self.child.to_dict(),
                 "onPointerDown": self.onPointerDown,
                 "onPointerUp": self.onPointerUp,
                 "onPointerMove": self.onPointerMove,
                 "onPointerHover": self.onPointerHover
            }
        }
    
# Positioned
class Positioned(Widget):
    def __init__(self, child, id=None,
                 left=None, top=None, right=None, bottom=None, width=None, height=None):
        super().__init__(id)
        self.child = child
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom
        self.width = width
        self.height = height

    def to_dict(self):
        return {
            "type": "Positioned",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "child": self.child.to_dict(),
                "left": self.left,
                "top": self.top,
                "right": self.right,
                "bottom": self.bottom,
                "width": self.width,
                "height": self.height
            }
        }

# Row
class Row(Widget):
    def __init__(self, children=None, id=None):
        super().__init__(id)
        self.children = children or []

    def to_dict(self):
        return {
            "type": "Row",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "children": [c.to_dict() for c in self.children]
            }
        }

# Slider
class Slider(Widget):
    def __init__(self, value=0.0, on_changed=None, min=0.0, max=1.0, divisions = None, id=None):
        super().__init__(id)
        self.value = value
        self.on_changed = on_changed
        self.min = min
        self.max = max
        self.divisions = divisions

    def to_dict(self):
        return {
            "type": "Slider",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "value": self.value,
                "min": self.min,
                "max": self.max,
                "divisions": self.divisions,
                "on_changed": self.on_changed
            }
        }

# SingleChildScrollView
class SingleChildScrollView(Widget):
    def __init__(self, child=None, id=None):
        super().__init__(id)
        self.child = child

    def to_dict(self):
        return {
            "type": "SingleChildScrollView",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "child": self.child.to_dict()
            }
        }
    
# SizedBox
class SizedBox(Widget):
    def __init__(self, width=None, height=None, child=None, id=None):
        super().__init__(id)
        self.width = width
        self.height = height
        self.child = child

    def to_dict(self):
        return {
            "type": "SizedBox",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "width": self.width, "height": self.height,
                "child": self.child.to_dict()
            }
        }
    
# Stack
class Stack(Widget):
    def __init__(self, children=None, alignment=None, fit=None, clipBehavior=None, id=None):
        super().__init__(id)
        self.children = children or []
        self.alignment = alignment
        self.fit = fit
        self.clipBehavior = clipBehavior

    def to_dict(self):
        return {
            "type": "Stack",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "children": [c.to_dict() for c in self.children],
                "alignment": self.alignment,
                "fit": self.fit,
                "clipBehavior": self.clipBehavior
            }
        }

# Text
class Text(Widget):
    def __init__(self, data, style=None, id=None):
        super().__init__(id)
        self.data = data
        self.style = style

    def to_dict(self):
        style = self.style
        if style!=None: style = style.to_dict()
        return {
            "type": "Text",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "data": self.data,
                "style": style
            }
        }

# TextField
class TextField(Widget):
    def __init__(self, data, rows=None, style=None, id=None):
        super().__init__(id)
        self.data = data
        self.rows = rows or 1
        self.style = style

    def to_dict(self):
        return {
            "type": "TextField",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "rows": self.rows,
                "data": self.data, "style": self.style
            }
        }

# TextStyle
class TextStyle(Widget):
    def __init__(self, font_size=None, color=None, bold=False):
        super().__init__()
        self.font_size = font_size
        self.color = color
        self.bold = bold

    def to_dict(self):
        return {
            "type": "TextStyle",
            "id": self.id,
            "kwargs": {
                "font_size": self.font_size,
                "color": self.color,
                "bold": self.bold
            }
        }

# RichText
class RichText(Widget):
    def __init__(self, text, style=None, id=None):
        super().__init__(id)
        self.text = text
        self.style = style

    def to_dict(self):
        s=None
        if self.style: s=self.style.to_dict()
        return {
            "type": "RichText",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "text": self.text,
                "style": s
            }
        }
    