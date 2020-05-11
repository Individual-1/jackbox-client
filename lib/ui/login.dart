import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:jackbox_client/model/jackbox.dart';

import 'package:provider/provider.dart';

import 'package:jackbox_client/bloc/jackbox_bloc.dart';

// Login implements SessionLobbyState
class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _roomFilter = new TextEditingController();
  final TextEditingController _nameFilter = new TextEditingController();
  final TextEditingController _error = new TextEditingController();
  bool _allowJoin = false;

  final RegExp _roomRegex = new RegExp(r'[^A-Z]');
  final RegExp _nameRegex = new RegExp(r'[^A-Z0-9]');

  SessionLoginState state;

  String _roomCode = "";
  String _name = "";

  StreamSubscription _streamSub;
  Stream _prevStream;

  void _listen(Stream<BlocRouteTransition> stream) {
    _streamSub = stream.listen((event) {
      if (event.update) {
        if (event.state is SessionLoginState) {
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

  @override
  void initState() {
    super.initState();

    _roomFilter.addListener(_roomListener);
    _nameFilter.addListener(_nameListener);
  }

  void _roomListener() {
    if (_roomFilter.text.isEmpty) {
      _roomCode = "";
      _allowJoin = false;
    } else if (_roomRegex.hasMatch(_roomFilter.text)) {
      _error.text = "Room name must be alphabetical characters only";
      _allowJoin = false;
    }
    else {
      _roomCode = _roomFilter.text;
      _allowJoin = true;
    }
  }

  void _nameListener() {
    if (_nameFilter.text.isEmpty) {
      _name = "";
      _allowJoin = false;
    } else if (_nameRegex.hasMatch(_nameFilter.text)) {
      _error.text = "Name can only be composed of alphanumeric characters";
      _allowJoin = false;
    } else {
      _name = _nameFilter.text;
      _allowJoin = true;
    }
  }

  Widget _buildTextFields() {
    return Container(
      child: Column(
        children: [
          Container(
            child: TextField(
              controller: _nameFilter,
              decoration: InputDecoration(
                labelText: 'Name'
              )
            )
          ),
          Container(
            child: TextField(
              controller: _roomFilter,
              decoration: InputDecoration(
                labelText: 'Room Code'
              ),
            )
            ),
            Container(
              child: TextField(
                controller: _error
              )
            )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final JackboxBloc bloc = Provider.of<JackboxBloc>(context);
    Map<String, dynamic> args = ModalRoute.of(context).settings.arguments;

    if (args.containsKey('name')) {
      _nameFilter.text = args['name'];
    }

    if (args.containsKey('roomCode')) {
      _roomFilter.text = args['roomCode'];
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Container(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildTextFields(),
            RaisedButton(
              child: Text('Join'),
              onPressed: _allowJoin ? () {
                bloc.sendEvent(JackboxLoginEvent(name: _name, roomCode: _roomCode));
              } : null,
            )
          ],
        )
      )
    );
  }
}