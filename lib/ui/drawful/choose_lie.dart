import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:jackbox_client/model/drawful.dart';

import 'package:provider/provider.dart';

import 'package:jackbox_client/bloc/jackbox_bloc.dart';

// DrawfulChooseLie implements DrawfulChooseLieState
class DrawfulChooseLieWidget extends StatefulWidget {
  final DrawfulChooseLieState state;

  DrawfulChooseLieWidget({this.state});

  @override
  _DrawfulChooseLieWidgetState createState() => _DrawfulChooseLieWidgetState(state: state);
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text?.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class Item {
  String choice;
  bool chosen;

  Item({this.choice}) {
    chosen = false;
  }
}

class _DrawfulChooseLieWidgetState extends State<DrawfulChooseLieWidget> {
  DrawfulChooseLieState state;

  StreamSubscription _streamSub;
  Stream _prevStream;

  bool enabled = true;
  List<Item> items = List<Item>();

  final scaffoldKey = GlobalKey<ScaffoldState>();

  _DrawfulChooseLieWidgetState({this.state});

  void _listen(Stream<BlocRouteTransition> stream) {
    _streamSub = stream.listen((event) {
      if (event.update) {
        if (event.state is DrawfulChooseLieState && event.state != state) {
          setState(() {
            state = event.state;
          });
        }
      } else {
        Navigator.pushNamed(context, event.route, arguments: event.state);
      }
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

  void _showToast(BuildContext context, String toastContents) {
    scaffoldKey.currentState.showSnackBar(
      SnackBar(
          content: Text(toastContents),
          action: SnackBarAction(
              label: 'DISMISS',
              onPressed: scaffoldKey.currentState.hideCurrentSnackBar)),
    );
  }

  Widget _buildChoiceList(BuildContext context) {
    final JackboxBloc bloc = Provider.of<JackboxBloc>(context);

    return ListView.separated(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Card(
          shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey[100], width: 2.0),
              borderRadius: BorderRadius.circular(4.0)),
          child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: ListTile(
                title: Text(items[index].choice),
                enabled: !enabled,
                onTap: () {
                  setState(() {
                    enabled = true;
                    bloc.sendEvent(
                        DrawfulChooseLieEvent(choice: items[index].choice));
                  });
                },
              )),
        );
      },
      separatorBuilder: (context, index) {
        return Divider();
      },
    );
  }

  Widget _buildLikeList(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return LikeChoiceWidget(choice: items[index].choice);
      },
      separatorBuilder: (context, index) {
        return Divider();
      },
    );
  }

  Widget _buildInstructions(BuildContext context) {
    if (enabled) {
      return Text('Select a choice');
    } else {
      return Text('Select items to like');
    }
  }

  Widget _buildList(BuildContext context) {
    if (enabled) {
      return _buildChoiceList(context);
    } else {
      return _buildLikeList(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> choices = state.choices.toList();
    choices.remove(state.myEntry);

    for (String choice in choices) {
      items.add(Item(choice: choice));
    }

    if (state.isAuthor) {
      return Container(
        child: Center(
          child: Text('This is your drawing'),
        ),
      );
    } else {
      return Scaffold(
          key: scaffoldKey,
          backgroundColor: Colors.grey[100],
          body: Container(
              padding: EdgeInsets.all(8.0),
              child: Column(
                children: [
                  _buildInstructions(context),
                  SizedBox(height: 25.0),
                  _buildList(context),
                ],
              )));
    }
  }
}

class LikeChoiceWidget extends StatefulWidget {
  final String choice;

  const LikeChoiceWidget({Key key, this.choice}) : super(key: key);

  @override
  _LikeChoiceWidgetState createState() => _LikeChoiceWidgetState();
}

class _LikeChoiceWidgetState extends State<LikeChoiceWidget> {
  bool selected = false;

  @override
  Widget build(BuildContext context) {
    final JackboxBloc bloc = Provider.of<JackboxBloc>(context);

    return new Card(
      shape: selected
          ? RoundedRectangleBorder(
              side: BorderSide(color: Colors.blue[100], width: 2.0),
              borderRadius: BorderRadius.circular(4.0))
          : RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey[100], width: 2.0),
              borderRadius: BorderRadius.circular(4.0)),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(widget.choice),
          Checkbox(
              value: selected,
              onChanged: selected
                  ? null
                  : (value) {
                      selected = value;
                      bloc.sendEvent(
                          DrawfulLikeChoiceEvent(choice: widget.choice));
                    }),
        ]),
      ),
    );
  }
}
