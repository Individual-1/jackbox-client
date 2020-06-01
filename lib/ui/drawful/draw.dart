import 'dart:async';
import 'dart:ui';
import 'dart:math';
import 'dart:convert';
import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:file_picker_web/file_picker_web.dart';
import 'package:provider/provider.dart';

import 'package:jackbox_client/bloc/jackbox_bloc.dart';
import 'package:jackbox_client/model/drawful.dart';

// Draw implements DrawfulDrawingState
class DrawfulDrawWidget extends StatefulWidget {
  final bool standalone;
  final DrawfulDrawingState state;

  DrawfulDrawWidget({this.standalone, this.state});

  @override
  _DrawfulDrawWidgetState createState() =>
      _DrawfulDrawWidgetState(standalone: standalone, state: state);
}

enum SelectedMode { StrokeWidth, Color }

enum EditMode { Drawing, Text }

class _DrawfulDrawWidgetState extends State<DrawfulDrawWidget> {
  Color _selectedColor = Colors.black;
  Color _pickerColor = Colors.black;
  double _strokeWidth = 3.0;
  bool _showBottomList = false;
  StrokeCap _strokeCap = StrokeCap.round;
  SelectedMode _selectedMode = SelectedMode.StrokeWidth;
  List<Color> _colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.amber,
    Colors.black
  ];

  PaintingStyle _paintStyle = PaintingStyle.stroke;

  final TextEditingController _importController = TextEditingController();

  LineNotifier _ln;
  DrawingPainter _drawPaint;
  GestureDetector _gd;
  Widget _canvasContainer;
  Widget _canvas;

  Widget _drawInstructions;
  Widget _itemBar;
  Widget _submitButton;

  DrawfulDrawingState state;

  StreamSubscription _streamSub;
  Stream _prevStream;

  bool standalone;

  final _instrKey = GlobalKey();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _strokeFormKey = GlobalKey<FormState>();

  _DrawfulDrawWidgetState({this.standalone, this.state});

  void _listen(Stream<BlocRouteTransition> stream) {
    _streamSub = stream.listen((event) {
      if (event.update) {
        if (event.state is DrawfulDrawingState &&
            event.state.shouldUpdate(state)) {
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
    _ln = LineNotifier();
    _drawPaint = DrawingPainter(_ln);
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _importController.dispose();
    super.dispose();
  }

  void _panStart(DragStartDetails details) {
    if (_ln.checkInBounds(details.localPosition)) {
      _ln.startStroke(
          details.localPosition,
          _strokeWidth,
          Paint()
            ..strokeCap = _strokeCap
            ..isAntiAlias = true
            ..color = _selectedColor
            ..strokeWidth = _strokeWidth
            ..style = _paintStyle);
    } else {
      _ln.endStroke();
    }
  }

  void _panUpdate(DragUpdateDetails details) {
    if (_ln.checkInBounds(details.localPosition)) {
      _ln.appendStroke(
          details.localPosition,
          _strokeWidth,
          Paint()
            ..strokeCap = _strokeCap
            ..isAntiAlias = true
            ..color = _selectedColor
            ..strokeWidth = _strokeWidth
            ..style = _paintStyle);
    } else {
      _ln.endStroke();
    }
  }

  void _panEnd(DragEndDetails details) {
    _ln.endStroke();
  }

  void _showToast(BuildContext context, String toastContents) {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
          content: Text(toastContents),
          action: SnackBarAction(
              label: 'DISMISS',
              onPressed: _scaffoldKey.currentState.hideCurrentSnackBar)),
    );
  }

  @override
  Widget build(BuildContext context) {
    JackboxBloc bloc;
    if (!standalone) {
      bloc = Provider.of<JackboxBloc>(context);
    }

    _gd = GestureDetector(
      onPanStart: _panStart,
      onPanUpdate: _panUpdate,
      onPanEnd: _panEnd,
    );

    _canvas = Container(
        decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black,
              width: 5,
            ),
            borderRadius: BorderRadius.circular(8)),
        child: CustomPaint(
          painter: _drawPaint,
          child: _gd,
        ));

    _drawInstructions = Container(
        child: Text(
      state != null ? state.prompt : 'Draw',
      key: _instrKey,
      style: TextStyle(fontSize: 30),
    ));

    _canvasContainer = Container(
        child: Center(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            _drawInstructions,
            Expanded(
                child: AspectRatio(
              aspectRatio: 0.8,
              child: _canvas,
            ))
          ]),
    ));

    _itemBar = Padding(
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
                            if (_selectedMode == SelectedMode.StrokeWidth)
                              _showBottomList = !_showBottomList;
                            _selectedMode = SelectedMode.StrokeWidth;
                          });
                        }),
                    // Select color
                    IconButton(
                        icon: Icon(Icons.color_lens),
                        onPressed: () {
                          setState(() {
                            if (_selectedMode == SelectedMode.Color)
                              _showBottomList = !_showBottomList;
                            _selectedMode = SelectedMode.Color;
                          });
                        }),
                    // Undo
                    IconButton(
                        icon: Icon(Icons.undo),
                        onPressed: () {
                          setState(() {
                            _ln.removeLast();
                          });
                        }),
                    // Export Drawing json
                    IconButton(
                        icon: Icon(Icons.save),
                        onPressed: () {
                          String js = _ln.exportLines(Size(240.0, 300.0));
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
                        onPressed: () async {
                          await _importPicker(context);
                        }),
                  ],
                ),
                Visibility(
                  child: (_selectedMode == SelectedMode.Color)
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _getColorList(),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [_getStrokeForm()]),
                  visible: _showBottomList,
                ),
              ],
            ),
          )),
    );

    _submitButton = FloatingActionButton(
      onPressed: () {
        if (_ln.lines.length <= 0) {
          _showToast(context, 'Canvas must not be empty');
        } else if (bloc != null) {
          bloc.sendEvent(DrawfulSubmitDrawingEvent(
              isPlayerPicture:
                  state != null ? (state.lobbyState != null) : false,
              lines: _ln.linesToListMap(Size(240.0, 300.0))));
        } else {
          _showToast(context, 'No endpoint to submit to');
        }
      },
      child: Icon(Icons.arrow_forward_ios),
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: _itemBar,
      floatingActionButton: _submitButton,
      body: _canvasContainer,
    );
  }

  _getStrokeForm() {
    TextEditingController controller = new TextEditingController();
    controller.text = _strokeWidth.toString();

    return Form(
        key: _strokeFormKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 50.0,
              height: 30.0,
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  WhitelistingTextInputFormatter.digitsOnly
                ],
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Enter a value';
                  } else {
                    return null;
                  }
                },
              ),
            ),
            SizedBox(
                height: 30.0,
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: RaisedButton(
                      onPressed: () {
                        if (_strokeFormKey.currentState.validate()) {
                          double result = 0.0;

                          try {
                            result = double.parse(controller.text);
                          } catch (e) {
                            return;
                          }

                          setState(() {
                            _strokeWidth = result;
                          });
                        }
                      },
                      child: Text('Save'),
                    ))),
          ],
        ));
  }

  _getColorList() {
    List<Widget> listWidget = List();
    for (Color color in _colors) {
      listWidget.add(_colorCircle(color));
    }
    Widget colorPicker = GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          child: AlertDialog(
            title: const Text('Color Selector'),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: _pickerColor,
                enableAlpha: false,
                paletteType: PaletteType.hsv,
                onColorChanged: (color) {
                  _pickerColor = color;
                },
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: const Text('Save'),
                onPressed: () {
                  setState(() => _selectedColor = _pickerColor);
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
          _selectedColor = color;
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

  Future _importPicker(BuildContext context) async {
    File file = await FilePicker.getFile() ?? null;

    if (file != null) {
      FileReader reader = new FileReader();
      reader.onLoad.listen((fileEvent) {
        String fileContent = reader.result;

        bool result = this._ln.importLines(fileContent);
        if (!result) {
          _showToast(context, 'Failed to import file');
        }
      });

      reader.readAsText(file);
    } else {
      _showToast(context, 'Failed to import file');
    }

    return;
  }
}

class PictureLine {
  Paint paint;
  List<Offset> points;
  double thickness;
  bool open;

  PictureLine({this.thickness, this.points, this.paint}) {
    open = true;
  }

  factory PictureLine.fromPictureLine(PictureLine line) {
    List<Offset> points = List<Offset>();
    Paint paint = Paint();
    Color color = Color(line.paint.color.value);

    for (Offset off in line.points) {
      points.add(Offset(off.dx, off.dy));
    }

    paint
      ..strokeCap = line.paint.strokeCap
      ..isAntiAlias = line.paint.isAntiAlias
      ..color = color
      ..strokeWidth = line.paint.strokeWidth
      ..style = line.paint.style;

    return PictureLine(
      paint: paint,
      points: points,
      thickness: line.thickness,
    );
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

    // Set some defaults because this information isn't stored
    Paint paint = Paint()
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke;

    if (json.containsKey('color')) {
      String color = json['color'];

      if (color.startsWith('#')) {
        color = color.substring(1);
      }

      // Need to specify full opaque alpha because we don't save that channel
      paint.color = Color(0xFF000000 | int.parse(color, radix: 16));
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

class SerializedLines {
  Size canvasSize;
  List<PictureLine> lines;

  SerializedLines({this.canvasSize, this.lines});

  factory SerializedLines.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('lines') ||
        !json.containsKey('canvasWidth') ||
        !json.containsKey('canvasHeight')) {
      throw FormatException(
          "Missing required fields 'lines' or 'canvasWidth/Height'");
    }

    return SerializedLines(
      canvasSize:
          Size(json['canvasWidth'] as double, json['canvasHeight'] as double),
      lines: (json['lines'] as List)
          ?.map((e) => e == null
              ? null
              : PictureLine.fromJson(e as Map<String, dynamic>))
          ?.toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'canvasWidth': canvasSize.width,
      'canvasHeight': canvasSize.height,
      'lines': lines,
    };
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
      line.thickness = max(line.thickness * avgScale, 1.0);

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

    return jsonEncode(SerializedLines(
      canvasSize: scaleTo,
      lines: lineCopy,
    ));
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

  bool importLines(String json) {
    dynamic parsed;
    SerializedLines slines;

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
      return false;
    }

    try {
      slines = SerializedLines.fromJson(parsed);
    } catch (e) {
      return false;
    }

    for (PictureLine line in slines.lines) {
      line.paint.strokeCap = strokeCap;
      line.paint.style = paintStyle;
    }

    _resizeLines(slines.canvasSize, this.canvasSize, slines.lines);

    lines.clear();

    lines.addAll(slines.lines);
    notifyListeners();

    return true;
  }
}

class DrawingPainter extends CustomPainter {
  final LineNotifier ln;

  DrawingPainter(this.ln) : super(repaint: ln);

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

    for (var line in this.ln.lines) {
      canvas.drawPoints(PointMode.polygon, line.points, line.paint);
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
