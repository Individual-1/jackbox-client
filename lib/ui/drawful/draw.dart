import 'dart:async';
import 'dart:ui';
import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:jackbox_client/model/drawful.dart';
import 'package:provider/provider.dart';

import 'package:jackbox_client/bloc/jackbox_bloc.dart';

// Draw implements DrawfulDrawingState
class DrawfulDrawWidget extends StatefulWidget {
  final bool standalone;
  final DrawfulDrawingState state;

  DrawfulDrawWidget({this.standalone, this.state});

  @override
  _DrawfulDrawWidgetState createState() =>
      _DrawfulDrawWidgetState(standalone: standalone, state: state);
}

class PictureLine {
  Paint paint;
  List<Offset> points;
  double thickness;
  bool open;

  PictureLine({this.thickness, this.points, this.paint}) {
    open = true;
  }

  factory PictureLine.fromJson(Map<String, dynamic> json) {
    List<Offset> points = List<Offset>();

    if (json.containsKey('points')) {
      for (Map<String, dynamic> point in json['points']) {
        if (point.containsKey('x') && point.containsKey('y')) {
          dynamic xd = point['x'];
          dynamic yd = point['y'];

          double x;
          double y;

          if (xd is int) {
            x = xd.roundToDouble();
          } else if (xd is double) {
            x = xd;
          } else {
            throw FormatException('Failed to parse');
          }

          if (yd is int) {
            y = yd.roundToDouble();
          } else if (yd is double) {
            y = yd;
          } else {
            throw FormatException();
          }

          points.add(Offset(x, y));
        }
      }
    }

    Paint paint = Paint();

    if (json.containsKey('color')) {
      String color = json['color'];

      if (color.startsWith('#')) {
        color = color.substring(1);
      }

      paint.color = Color(int.parse(color, radix: 16));
    }

    double thickness = 3.0;
    if (json.containsKey('thickness')) {
      dynamic thick = json['thickness'];

      if (thick is int) {
        thickness = thick.roundToDouble();
      } else if (thick is double) {
        thickness = thick;
      }
    }

    paint.strokeWidth = thickness;

    PictureLine result = PictureLine(
      thickness: thickness,
      points: points,
      paint: paint,
    );

    result.open = false;

    return result;
  }

  Map<String, dynamic> toJson() {
    int base = paint.color.value & 0xFFFFFF;
    List<Map> pointsJson = List<Map>();

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

class _DrawfulDrawWidgetState extends State<DrawfulDrawWidget> {
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

  final TextEditingController importController = TextEditingController();

  LineNotifier ln;
  DrawingPainter drawPaint;
  GestureDetector gd;
  Widget canvasContainer;
  Widget canvas;

  Widget drawInstructions;
  GlobalKey instrKey;
  Widget itemBar;
  Widget submitButton;

  DrawfulDrawingState state;

  StreamSubscription _streamSub;
  Stream _prevStream;

  bool standalone;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  _DrawfulDrawWidgetState({this.standalone, this.state});

  void _listen(Stream<BlocRouteTransition> stream) {
    _streamSub = stream.listen((event) {
      if (event.update) {
        if (event.state is DrawfulDrawingState) {
          setState(() {
            state = event.state;
          });
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!standalone) {
      final JackboxBloc bloc = Provider.of<JackboxBloc>(context);
      if (bloc.jackboxRoute != _prevStream) {
        _streamSub?.cancel();
        _prevStream = bloc.jackboxRoute;
        _listen(bloc.jackboxRoute);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    ln = LineNotifier();
    drawPaint = DrawingPainter(ln);
    instrKey = GlobalKey();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    importController.dispose();
    super.dispose();
  }

  void _panStart(DragStartDetails details) {
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

  void _panUpdate(DragUpdateDetails details) {
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

  void _panEnd(DragEndDetails details) {
    ln.endStroke();
  }

  void _showToast(BuildContext context, String toastContents) {
    scaffoldKey.currentState.showSnackBar(
      SnackBar(
          content: Text(toastContents),
          action: SnackBarAction(
              label: 'DISMISS',
              onPressed: scaffoldKey.currentState.hideCurrentSnackBar)),
    );
  }

  @override
  Widget build(BuildContext context) {
    JackboxBloc bloc;
    if (!standalone) {
      bloc = Provider.of<JackboxBloc>(context);
    }

    gd = GestureDetector(
      onPanStart: _panStart,
      onPanUpdate: _panUpdate,
      onPanEnd: _panEnd,
    );

    canvas = Container(
        decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black,
              width: 5,
            ),
            borderRadius: BorderRadius.circular(8)),
        child: CustomPaint(
          painter: drawPaint,
          child: gd,
        ));

    drawInstructions = Container(
        child: Text(
      state != null ? state.prompt : 'Draw',
      key: instrKey,
      style: TextStyle(fontSize: 30),
    ));

    canvasContainer = Container(
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

    itemBar = Padding(
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
                    // Set stroke width
                    IconButton(
                        icon: Icon(Icons.album),
                        onPressed: () {
                          setState(() {
                            if (selectedMode == SelectedMode.StrokeWidth)
                              showBottomList = !showBottomList;
                            selectedMode = SelectedMode.StrokeWidth;
                          });
                        }),
                    // Select color
                    IconButton(
                        icon: Icon(Icons.color_lens),
                        onPressed: () {
                          setState(() {
                            if (selectedMode == SelectedMode.Color)
                              showBottomList = !showBottomList;
                            selectedMode = SelectedMode.Color;
                          });
                        }),
                    // Undo
                    IconButton(
                        icon: Icon(Icons.undo),
                        onPressed: () {
                          setState(() {
                            ln.removeLast();
                          });
                        }),
                    // Export Drawing json
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
                                    child: _exportDialog(js));
                              });
                        }),
                    // Import Drawing json
                    IconButton(
                        icon: Icon(Icons.file_upload),
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return Dialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(40)),
                                    child: _importDialog());
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

    submitButton = FloatingActionButton(
      onPressed: () {
        if (ln.lines.length <= 0) {
          _showToast(context, 'Canvas must not be empty');
        } else if (bloc != null) {
          bloc.sendEvent(DrawfulSubmitDrawingEvent(
              isPlayerPicture:
                  state != null ? (state.lobbyState != null) : false,
              lines: ln.linesToListMap(Size(240.0, 300.0))));
        } else {
          _showToast(context, 'No endpoint to submit to');
        }
      },
      child: Icon(Icons.arrow_forward_ios),
    );

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: itemBar,
      floatingActionButton: submitButton,
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

  Widget _exportDialog(String text) {
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
                  _showToast(context, 'Copied data to clipboard');
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

  Widget _importDialog() {
    return Container(
        padding: const EdgeInsets.all(20),
        child: AspectRatio(
          aspectRatio: 0.8,
          child: Column(children: [
            FlatButton(
                child: Text("Import"),
                color: Colors.grey[100],
                onPressed: () {
                  if (importController.text == '') {
                    _showToast(context, 'Nothing to import');
                  } else {
                    String result = ln.importLines(importController.text);

                    if (result != '') {
                      _showToast(context, result);
                    }
                  }
                }),
            Flexible(
                child: SingleChildScrollView(
                    child: TextField(
              controller: importController,
            ))),
          ]),
        ));
  }
}

class LineNotifier extends ChangeNotifier {
  List<PictureLine> lines;
  Size canvasSize;

  LineNotifier() {
    this.lines = List();
    this.canvasSize = Size.zero;
  }

  void startStroke(Offset pos, double strokeWidth, Paint paint) {
    lines.add(PictureLine(
      thickness: strokeWidth,
      points: List<Offset>.filled(1, pos, growable: true),
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
        points: List<Offset>.filled(1, pos, growable: true),
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

  void forceSync() {
    notifyListeners();
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
    List<PictureLine> lineCopy = List();

    for (PictureLine line in this.lines) {
      lineCopy.add(PictureLine());
      lineCopy.last.thickness = line.thickness;
      lineCopy.last.paint = Paint()
        ..strokeCap = line.paint.strokeCap
        ..isAntiAlias = line.paint.isAntiAlias
        ..color = line.paint.color
        ..strokeWidth = line.paint.strokeWidth
        ..style = line.paint.style;

      lineCopy.last.points = List();
      for (Offset off in line.points) {
        lineCopy.last.points.add(Offset(off.dx, off.dy));
      }
    }

    if (this.canvasSize != scaleTo) {
      _resizeLines(this.canvasSize, scaleTo, lineCopy);
    }

    return jsonEncode(lineCopy);
  }

  List<Map<String, dynamic>> linesToListMap(Size scaleTo) {
    List<PictureLine> lineCopy = List();

    for (PictureLine line in this.lines) {
      lineCopy.add(PictureLine());
      lineCopy.last.thickness = line.thickness;
      lineCopy.last.paint = Paint()
        ..strokeCap = line.paint.strokeCap
        ..isAntiAlias = line.paint.isAntiAlias
        ..color = line.paint.color
        ..strokeWidth = line.paint.strokeWidth
        ..style = line.paint.style;

      lineCopy.last.points = List();
      for (Offset off in line.points) {
        lineCopy.last.points.add(Offset(off.dx, off.dy));
      }
    }

    if (this.canvasSize != scaleTo) {
      _resizeLines(this.canvasSize, scaleTo, lineCopy);
    }

    List<Map<String, dynamic>> result = List<Map<String, dynamic>>();

    for (PictureLine line in lineCopy) {
      result.add(line.toJson());
    }

    return result;
  }

  String importLines(String json) {
    dynamic parsed;

    StrokeCap strokeCap;
    PaintingStyle paintStyle;

    if (this.lines.length > 0) {
      strokeCap = lines[0].paint.strokeCap;
      paintStyle = lines[0].paint.style;
    } else {
      strokeCap = StrokeCap.round;
      paintStyle = PaintingStyle.stroke;
    }

    try {
      parsed = jsonDecode(json);
    } catch (e) {
      return e.toString();
    }

    if (!(parsed is List<dynamic>)) {
      return 'Malformed input';
    } else {
      lines.clear();
      for (dynamic entry in parsed) {
        if (entry is Map<String, dynamic>) {
          PictureLine tmp;

          try {
            tmp = PictureLine.fromJson(entry);
          } catch (e) {
            return e.toString();
          }

          tmp.paint.strokeCap = strokeCap;
          tmp.paint.style = paintStyle;

          lines.add(tmp);
          notifyListeners();
        }
      }
    }

    return '';
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

    Paint canvasFill = Paint();
    canvasFill.color = Colors.white;
    canvasFill.style = PaintingStyle.fill;
    canvas.drawRect(rect, canvasFill);

    for (var line in ln.lines) {
      Path linePath = Path();

      linePath.addPolygon(line.points, false);
      canvas.drawPath(linePath, line.paint);
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
