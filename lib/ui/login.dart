import 'dart:ui';
import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  Color selectedColor = Colors.black;
  Color pickerColor = Colors.black;
  double strokeWidth = 3.0;
  bool showBottomList = false;
  StrokeCap strokeCap = StrokeCap.round;
  List<Color> colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.amber,
    Colors.black
  ];

  PaintingStyle paintStyle = PaintingStyle.stroke;

  LineNotifier ln;
  DrawingPainter drawPaint;
  GestureDetector gd;
  Widget canvasContainer;
  Widget canvas;

  Widget drawInstructions;
  GlobalKey instrKey;
  Widget itemBar;

  @override
  void initState() {
    super.initState();
    ln = new LineNotifier();
    drawPaint = new DrawingPainter(ln);
    instrKey = new GlobalKey();
  }

  void panStart(DragStartDetails details) {
    if (ln.checkInBounds(details.localPosition)) {
      ln.startStroke(
          details.localPosition,
          strokeWidth,
          Paint()
            ..strokeCap = strokeCap
            ..isAntiAlias = true
            ..color = selectedColor
            ..strokeWidth = strokeWidth
            ..style = paintStyle);
    } else {
      ln.endStroke();
    }
  }

  void panUpdate(DragUpdateDetails details) {
    if (ln.checkInBounds(details.localPosition)) {
      ln.appendStroke(
          details.localPosition,
          strokeWidth,
          Paint()
            ..strokeCap = strokeCap
            ..isAntiAlias = true
            ..color = selectedColor
            ..strokeWidth = strokeWidth
            ..style = paintStyle);
    } else {
      ln.endStroke();
    }
  }

  void panEnd(DragEndDetails details) {
    ln.endStroke();
  }

  @override
  Widget build(BuildContext context) {
    gd = new GestureDetector(
      onPanStart: panStart,
      onPanUpdate: panUpdate,
      onPanEnd: panEnd,
    );

    canvas = Container(
        decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black,
              width: 5,
            ),
            borderRadius: BorderRadius.circular(8)),
        child: new CustomPaint(
          painter: drawPaint,
          child: gd,
        ));

    drawInstructions = Container(
        child: Text(
      "Draw",
      key: instrKey,
      style: TextStyle(fontSize: 30),
    ));

    canvasContainer = new Container(
        child: Center(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            drawInstructions,
            Expanded(
                child: AspectRatio(
              aspectRatio: 0.8,
              child: canvas,
            ))
          ]),
    ));

    itemBar = new Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50.0),
              color: Colors.lightBlue[200]),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    IconButton(
                        icon: Icon(Icons.album),
                        onPressed: () {
                          setState(() {
                            if (selectedMode == SelectedMode.StrokeWidth)
                              showBottomList = !showBottomList;
                            selectedMode = SelectedMode.StrokeWidth;
                          });
                        }),
                    IconButton(
                        icon: Icon(Icons.color_lens),
                        onPressed: () {
                          setState(() {
                            if (selectedMode == SelectedMode.Color)
                              showBottomList = !showBottomList;
                            selectedMode = SelectedMode.Color;
                          });
                        }),
                    IconButton(
                        icon: Icon(Icons.undo),
                        onPressed: () {
                          setState(() {
                            ln.removeLast();
                          });
                        }),
                    IconButton(
                        icon: Icon(Icons.save),
                        onPressed: () {
                          String js = ln.exportLines(Size(240.0, 300.0));
                          showDialog(
                              context: context,
                              builder: (context) {
                                return Dialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(40)),
                                    child: _copyTextDialog(js));
                              });
                        }),
                  ],
                ),
                Visibility(
                  child: (selectedMode == SelectedMode.Color)
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _getColorList(),
                        )
                      : Slider(
                          value: strokeWidth,
                          max: 50.0,
                          min: 0.0,
                          onChanged: (val) {
                            setState(() {
                              strokeWidth = val;
                            });
                          }),
                  visible: showBottomList,
                ),
              ],
            ),
          )),
    );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: itemBar,
      body: canvasContainer,
    );
  }

  _getColorList() {
    List<Widget> listWidget = List();
    for (Color color in colors) {
      listWidget.add(_colorCircle(color));
    }
    Widget colorPicker = GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          child: AlertDialog(
            title: const Text('Color Selector'),
            content: SingleChildScrollView(
              child: MaterialPicker(
                pickerColor: pickerColor,
                onColorChanged: (color) {
                  pickerColor = color;
                },
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: const Text('Save'),
                onPressed: () {
                  setState(() => selectedColor = pickerColor);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
      child: ClipOval(
        child: Container(
          padding: const EdgeInsets.only(bottom: 16.0),
          height: 36,
          width: 36,
          decoration: BoxDecoration(
              gradient: LinearGradient(
            colors: [Colors.red, Colors.green, Colors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )),
        ),
      ),
    );
    listWidget.add(colorPicker);
    return listWidget;
  }

  Widget _colorCircle(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color;
        });
      },
      child: ClipOval(
        child: Container(
          padding: const EdgeInsets.only(bottom: 16.0),
          height: 36,
          width: 36,
          color: color,
        ),
      ),
    );
  }
}

Widget _copyTextDialog(String text) {
  return Container(
      padding: const EdgeInsets.all(20),
      child: AspectRatio(
        aspectRatio: 0.8,
        child: Column(children: [
          FlatButton(
              child: Text("Copy to clipboard"),
              color: Colors.grey[100],
              onPressed: () {
                Clipboard.setData(ClipboardData(text: text));
              }),
          Flexible(
              child: SingleChildScrollView(
                  child: SelectableText(
            text,
            showCursor: true,
            textAlign: TextAlign.center,
          ))),
        ]),
      ));
}