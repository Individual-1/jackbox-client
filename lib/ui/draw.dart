import 'dart:async';
import 'dart:ui';
import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';

import 'package:jackbox_client/bloc/jackbox_bloc.dart';

// Draw implements DrawfulDrawingState
class Draw extends StatefulWidget {
  @override
  _DrawState createState() => _DrawState();
}

class PictureLine {
  Paint paint;
  List<Offset> points;
  double thickness;
  bool open;

  PictureLine({this.thickness, this.points, this.paint}) {
    open = true;
  }

  Map<String, dynamic> toJson() {
    int base = paint.color.value & 0xFFFFFF;
    List<Map> pointsJson = new List<Map>();

    for (Offset point in this.points) {
      pointsJson.add({
        'x': point.dx.round(),
        'y': point.dy.round(),
      });
    }

    return {
      'thickness': thickness.round(),
      'color': "#" + base.toRadixString(16).padLeft(6, '0'),
      'points': pointsJson,
    };
  }
}

enum SelectedMode { StrokeWidth, Color }

class _DrawState extends State<Draw> {
  Color selectedColor = Colors.black;
  Color pickerColor = Colors.black;
  double strokeWidth = 3.0;
  bool showBottomList = false;
  StrokeCap strokeCap = StrokeCap.round;
  SelectedMode selectedMode = SelectedMode.StrokeWidth;
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

  StreamSubscription _streamSub;
  Stream _prevStream;

  void _listen(Stream<BlocRouteTransition> stream) {
    _streamSub = stream.listen((event) { 
      Navigator.pushNamed(context, event.route, arguments: event.params);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final JackboxBloc bloc = Provider.of<JackboxBloc>(context);
    if (bloc.jackboxRoute != _prevStream) {
      _streamSub?.cancel();
      _prevStream = bloc.jackboxRoute;
      _listen(bloc.jackboxRoute);
    }
  }

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
    final JackboxBloc bloc = Provider.of<JackboxBloc>(context);
    Map<String, dynamic> args = ModalRoute.of(context).settings.arguments;

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

class LineNotifier extends ChangeNotifier {
  List<PictureLine> lines;
  Size canvasSize;

  LineNotifier() {
    this.lines = new List();
    this.canvasSize = Size.zero;
  }

  void startStroke(Offset pos, double strokeWidth, Paint paint) {
    lines.add(PictureLine(
      thickness: strokeWidth,
      points: new List<Offset>.filled(1, pos, growable: true),
      paint: paint,
    ));

    notifyListeners();
  }

  void appendStroke(Offset pos, double strokeWidth, Paint paint) {
    if (lines.length > 0 && lines.last.open) {
      lines.last.points.add(pos);
    } else {
      lines.add(PictureLine(
        thickness: strokeWidth,
        points: new List<Offset>.filled(1, pos, growable: true),
        paint: paint,
      ));
    }

    notifyListeners();
  }

  void endStroke() {
    if (lines.length > 0) {
      lines.last.open = false;
    }
    notifyListeners();
  }

  void removeLast() {
    if (lines.length > 0) {
      lines.removeLast();
      notifyListeners();
    }
  }

  bool checkInBounds(Offset localPos) {
    if (localPos.dx < 0 ||
        localPos.dy < 0 ||
        localPos.dx > this.canvasSize.width ||
        localPos.dy > this.canvasSize.height) {
      return false;
    }

    return true;
  }

  void resizeLines(Size target) {
    if (this.canvasSize != target) {
      _resizeLines(this.canvasSize, target, this.lines);
      this.canvasSize = target;
    }
  }

  void _resizeLines(Size initial, Size target, List<PictureLine> lineList) {
    double scaleX = target.width / initial.width;
    double scaleY = target.height / initial.height;
    double avgScale = (scaleX + scaleY) / 2;

    for (PictureLine line in lineList) {
      if (line.thickness > 1.0) {
        line.thickness = max(line.thickness * avgScale, 1.0);
      }

      for (int i = 0; i < line.points.length; i++) {
        line.points[i] = line.points[i].scale(scaleX, scaleY);
      }
    }
  }

  String exportLines(Size scaleTo) {
    List<PictureLine> lineCopy = new List();

    for (PictureLine line in this.lines) {
      lineCopy.add(PictureLine());
      lineCopy.last.thickness = line.thickness;
      lineCopy.last.paint = Paint()
        ..strokeCap = line.paint.strokeCap
        ..isAntiAlias = line.paint.isAntiAlias
        ..color = line.paint.color
        ..strokeWidth = line.paint.strokeWidth
        ..style = line.paint.style;

      lineCopy.last.points = new List();
      for (Offset off in line.points) {
        lineCopy.last.points.add(Offset(off.dx, off.dy));
      }
    }

    if (this.canvasSize != scaleTo) {
      _resizeLines(this.canvasSize, scaleTo, lineCopy);
    }

    return jsonEncode(lineCopy);
  }
}

class DrawingPainter extends CustomPainter {
  LineNotifier ln;

  DrawingPainter(LineNotifier ln) : super(repaint: ln) {
    this.ln = ln;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (this.ln.canvasSize == Size.zero) {
      this.ln.canvasSize = size;
    }

    if (this.ln.canvasSize != size) {
      this.ln.resizeLines(size);
    }

    var rect = Offset.zero & size;
    canvas.clipRect(rect);

    Paint canvasFill = new Paint();
    canvasFill.color = Colors.white;
    canvasFill.style = PaintingStyle.fill;
    canvas.drawRect(rect, canvasFill);

    for (var line in ln.lines) {
      Path linePath = new Path();

      linePath.addPolygon(line.points, false);
      canvas.drawPath(linePath, line.paint);
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
