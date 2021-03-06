import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:jackbox_client/model/jackbox.dart';

import 'package:provider/provider.dart';

import 'package:jackbox_client/bloc/jackbox_bloc.dart';

// Login implements SessionLoginState
class LoginWidget extends StatefulWidget {
  final SessionLoginState state;

  LoginWidget({this.state});

  @override
  _LoginWidgetState createState() => _LoginWidgetState(state: state);
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

class _LoginWidgetState extends State<LoginWidget> {
  final TextEditingController _roomFilter = TextEditingController();
  final TextEditingController _nameFilter = TextEditingController();

  final RegExp _roomRegex = RegExp(r'[A-Za-z]');
  final RegExp _nameRegex = RegExp(r'[A-Za-z0-9]');

  SessionLoginState state;

  StreamSubscription _streamSub;
  Stream _prevStream;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  _LoginWidgetState({this.state});

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }

  void _listen(Stream<BlocRouteTransition> stream) {
    _streamSub = stream.listen((event) {
      if (event.update) {
        if (event.state is SessionLoginState && event.state.shouldUpdate(state)) {
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

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameFilter,
      decoration: InputDecoration(
          contentPadding: EdgeInsets.fromLTRB(10.0, 7.5, 10.0, 7.5),
          hintText: 'Name',
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(20.0))),
      inputFormatters: [
        LengthLimitingTextInputFormatter(10),
        WhitelistingTextInputFormatter(_nameRegex),
        LowerCaseTextFormatter()
      ],
    );
  }

  Widget _buildRoomField() {
    return TextFormField(
      controller: _roomFilter,
      decoration: InputDecoration(
          contentPadding: EdgeInsets.fromLTRB(10.0, 7.5, 10.0, 7.5),
          hintText: 'Room Code',
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(20.0))),
      inputFormatters: [
        LengthLimitingTextInputFormatter(4),
        WhitelistingTextInputFormatter(_roomRegex),
        UpperCaseTextFormatter()
      ],
    );
  }

  Future _joinRoom(JackboxBloc bloc) async {
    if (_roomFilter.text == '' || _nameFilter.text == '') {
      _showToast(context, 'Missing room or name fields');
    }

    String roomCode = _roomFilter.text;
    String name = _nameFilter.text;
    bool valid = await bloc.isValidRoom(roomCode);

    if (valid) {
      bloc.sendEvent(JackboxLoginEvent(name: name, roomCode: roomCode));
    } else {
      _showToast(context, 'Invalid Room Code');
    }
  }

  @override
  Widget build(BuildContext context) {
    final JackboxBloc bloc = Provider.of<JackboxBloc>(context);

    return Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.grey[100],
        body: Container(
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: [
                SizedBox(
                    height: 150.0,
                    child: Image.asset(
                      "images/login.jpg",
                      fit: BoxFit.contain,
                    )),
                SizedBox(height: 50.0),
                _buildRoomField(),
                SizedBox(height: 25.0),
                _buildNameField(),
                SizedBox(height: 25.0),
                RaisedButton(
                  child: Text('Join'),
                  onPressed: () async {
                    await _joinRoom(bloc);
                  },
                ),
                SizedBox(height: 15.0)
              ],
            )));
  }
}
