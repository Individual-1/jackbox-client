import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:jackbox_client/model/drawful.dart';

import 'package:provider/provider.dart';

import 'package:jackbox_client/bloc/jackbox_bloc.dart';

// DrawfulEnterLie implements DrawfulEnterLieState
class DrawfulEnterLieWidget extends StatefulWidget {
  final DrawfulEnterLieState state;

  DrawfulEnterLieWidget({this.state});

  @override
  _DrawfulEnterLieWidgetState createState() =>
      _DrawfulEnterLieWidgetState(state: state);
}

class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text?.toLowerCase(),
      selection: newValue.selection,
    );
  }
}

class _DrawfulEnterLieWidgetState extends State<DrawfulEnterLieWidget> {
  final TextEditingController _entryFilter = TextEditingController();

  DrawfulEnterLieState state;

  StreamSubscription _streamSub;
  Stream _prevStream;

  bool enabled;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  _DrawfulEnterLieWidgetState({this.state});

  @override
  void initState() {
    super.initState();

    enabled = true;
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }

  void _listen(Stream<BlocRouteTransition> stream) {
    _streamSub = stream.listen((event) {
      if (event.update) {
        if (event.state is DrawfulEnterLieState && event.state.shouldUpdate(state)) {
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

  Widget _buildEntryField() {
    return TextFormField(
      controller: _entryFilter,
      enabled: enabled,
      decoration: InputDecoration(
          contentPadding: EdgeInsets.fromLTRB(10.0, 7.5, 10.0, 7.5),
          hintText: 'Enter Lie',
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(20.0))),
      inputFormatters: [
        //LengthLimitingTextInputFormatter(10),
        //WhitelistingTextInputFormatter(_entryRegex),
        LowerCaseTextFormatter()
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final JackboxBloc bloc = Provider.of<JackboxBloc>(context);

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
                  _buildEntryField(),
                  SizedBox(height: 25.0),
                  RaisedButton(
                    child: Text('Submit'),
                    onPressed: () {
                      // TODO: We don't handle duplicate entries
                      if (state.lie == '' && enabled) {
                        if (_entryFilter.text != '') {
                          setState(() {
                            bloc.sendEvent(DrawfulSubmitLieEvent(
                                lie: _entryFilter.text, usedSuggestion: false));
                            state.lie = _entryFilter.text;
                            enabled = false;
                          });
                        } else {
                          _showToast(context, 'Lie cannot be empty');
                        }
                      } else {
                        _showToast(context, 'Already submitted lie');
                      }
                    },
                  ),
                  SizedBox(height: 15.0)
                ],
              )));
    }
  }
}
