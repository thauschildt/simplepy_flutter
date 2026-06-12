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
- Layout: Column, Row, Wrap, Divider, Expanded, Flexible, Padding, GridView, ListView, ListTile, Stack, Center, SizedBox, Positioned, SingleChildScrollView
- Input: TextField, Slider, Button, Checkbox, Switch, DropdownButton/DropdownMenuItem
- Display: Text, Image, RichText, Icon, Tooltip
- Interaction: InkWell, Listener, Url
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
    def __init__(self, text, onPressed=None, id=None):
        super().__init__(id)
        self.text = text
        self.onPressed = onPressed

    def to_dict(self):
        return {
            "type": "Button",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "text": self.text,
                "onPressed": self.onPressed
            }
        }
    
# Card
class Card(Widget):
    def __init__(self, child, color=None, shadowColor=None, elevation=None, id=None):
        super().__init__(id)
        self.child = child
        self.color = color
        self.shadowColor = shadowColor
        self.elevation = elevation

    def to_dict(self):
        return {
            "type": "Card",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "child": self.child.to_dict(),
                "color": self.color,
                "shadowColor": self.shadowColor,
                "elevation": self.elevation
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

# Checkbox
class Checkbox(Widget):
    def __init__(self, value = False, onChanged=None, id=None):
        super().__init__(id)
        self.value = value
        self.onChanged = onChanged

    def to_dict(self):
        return {
            "type": "Checkbox",
            "id": self.id,
            "kwargs": {
                "value": self.value,
                "onChanged": self.onChanged,
                "userid": self.userid
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
    
# Divider
class Divider(Widget):
    def __init__(self, height=None, color=None, thickness=None, indent=None, endIndent=None, id=None):
        super().__init__(id)
        self.height = height
        self.color = color
        self.thickness = thickness
        self.indent = indent
        self.endIndent = endIndent

    def to_dict(self):
        return {
            "type": "Divider",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "height": self.height,
                "color": self.color,
                "thickness": self.thickness,
                "indent": self.indent,
                "endIndent": self.endIndent
            }
        }
    
# DropdownButton
class DropdownButton(Widget):
    def __init__(self, value = None, items=None, onChanged=None, id=None):
        super().__init__(id)
        self.items = items or []
        self.onChanged = onChanged
        self.value = value

    def to_dict(self):
        return {
            "type": "DropdownButton",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "items": [c.to_dict() for c in self.items],
                "value": self.value,
                "onChanged": self.onChanged
            }
        }

# DropdownMenuItem
class DropdownMenuItem(Widget):
    def __init__(self, child = None, value = None, id=None):
        super().__init__(id)
        self.child = child or []
        self.value = value

    def to_dict(self):
        return {
            "type": "DropdownMenuItem",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "child": self.child.to_dict(),
                "value": self.value
            }
        }


# Expanded
class Expanded(Widget):
    def __init__(self, child=None, flex=None, id=None):
        super().__init__(id)
        self.child = child
        self.flex = flex

    def to_dict(self):
        c=None
        if self.child: c=self.child.to_dict()
        return {
            "type": "Expanded",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "child": c,
                "flex": self.flex
            }
        }
    

# Flexible
class Flexible(Widget):
    def __init__(self, child=None, flex=None, fit=None, id=None):
        super().__init__(id)
        self.child = child
        self.flex = flex
        self.fit = fit

    def to_dict(self):
        c=None
        if self.child: c=self.child.to_dict()
        print("child: ",c)
        return {
            "type": "Flexible",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "child": c,
                "flex": self.flex,
                "fit": self.fit
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

# Icon
# codepoint is the unicode value: https://api.flutter.dev/flutter/material/Icons-class.html
class Icon(Widget):
    def __init__(self, codePoint, fontFamily=None, id=None):
        super().__init__(id)
        self.codePoint=codePoint
        self.fontFamily=fontFamily

    def to_dict(self):
        return {
            "type": "Icon",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "codePoint": self.codePoint,
                "fontFamily": self.fontFamily
            }
        }

# Image
class Image(Widget):
    def __init__(self, url=None, base64=None, id=None, width=None, height=None, opacity=None, scale=None):
        super().__init__(id)
        if url!=None and base64!=None:
            raise Exception("Image: You cannot specify both url and base64")
        self.url=url
        self.base64=base64
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
                "base64": self.base64,
                "width": self.width,
                "height": self.height,
                "scale": self.scale,
                "opacity": self.opacity
            }
        }
    
# InkWell
class InkWell(Widget):
    def __init__(self, child, onTap=None, id=None):
        super().__init__(id)
        self.child = child
        self.onTap = onTap

    def to_dict(self):
        return {
            "type": "InkWell",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "child": self.child.to_dict(),
                 "onTap": self.onTap
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
    
# ListTile
class ListTile(Widget):
    def __init__(self, children=[],  title="", subtitle=None, leading=None, trailing=None,
                 textColor = None, iconColor = None, tileColor = None,
                 onTap = None, onLongPress = None, id=None):
        super().__init__(id)
        self.children=children
        self.title=title
        self.subtitle=subtitle
        self.leading=leading
        self.trailing=trailing
        self.textColor=textColor
        self.iconColor=iconColor
        self.tileColor=tileColor
        self.onTap=onTap
        self.onLongPress=onLongPress
    def to_dict(self):
        leading = None
        if self.leading: leading = self.leading.to_dict()
        trailing = None
        if self.trailing: trailing = self.trailing.to_dict()
        title = None
        if self.title: title = self.title.to_dict()
        subtitle = None
        if self.subtitle: subtitle = self.subtitle.to_dict()
        return {
            "type": "ListTile",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "title": title,
                "subtitle": subtitle,
                "leading": leading,
                "trailing": trailing,
                "textColor": self.textColor,
                "iconColor": self.iconColor,
                "tileColor": self.tileColor,
                "onTap": self.onTap,
                "onLongPress": self.onLongPress
            }
        }
    
# ListView
class ListView(Widget):
    def __init__(self, children=[],  id=None):
        super().__init__(id)
        self.children=children
    def to_dict(self):
        return {
            "type": "ListView",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "children": [c.to_dict() for c in self.children]
            }
        }
    
# Padding
class Padding(Widget):
    def __init__(self, child, padding=0.0, id=None):
        super().__init__(id)
        self.child = child
        self.padding = padding
    
    def to_dict(self):
        return {
            "type": "Padding",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "child": self.child.to_dict(),
                "padding": self.padding
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
    def __init__(self, value=0.0, onChanged=None, min=0.0, max=1.0, divisions = None, id=None):
        super().__init__(id)
        self.value = value
        self.onChanged = onChanged
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
                "onChanged": self.onChanged
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
    
# Switch
class Switch(Widget):
    def __init__(self, value = False, onChanged=None, id=None):
        super().__init__(id)
        self.value = value
        self.onChanged = onChanged

    def to_dict(self):
        return {
            "type": "Switch",
            "id": self.id,
            "kwargs": {
                "value": self.value,
                "onChanged": self.onChanged,
                "userid": self.userid
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
    def __init__(self, fontSize=None, color=None, bold=False):
        super().__init__()
        self.fontSize = fontSize
        self.color = color
        self.bold = bold

    def to_dict(self):
        return {
            "type": "TextStyle",
            "id": self.id,
            "kwargs": {
                "fontSize": self.fontSize,
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
    
# Tooltip
class Tooltip(Widget):
    def __init__(self, child=None, message="", id=None):
        super().__init__(id)
        self.child = child or []
        self.message = message or []

    def to_dict(self):
        return {
            "type": "Tooltip",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "message": self.message,
                "child": self.child.to_dict()
            }
        }
    
# Wrap
class Wrap(Widget):
    def __init__(self, children=None, id=None):
        super().__init__(id)
        self.children = children or []

    def to_dict(self):
        return {
            "type": "Wrap",
            "id": self.id,
            "kwargs": {
                "userid": self.userid,
                "children": [c.to_dict() for c in self.children]
            }
        }
    
######### Widgets from additional packages #############

# Url
class Url(Widget):
    def __init__(self, url, label=None, id=None):
        super().__init__(id)
        self.url = url
        self.label = label

    def to_dict(self):
        label = self.label
        if isinstance(label, Widget): label=label.to_dict()
        return {
            "type": "Url",
            "id": self.id,
            "kwargs": {
                "url": self.url,
                "label": label
            }
        }