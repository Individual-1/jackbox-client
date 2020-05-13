import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jackbox_client/model/drawful.dart';

import 'package:provider/provider.dart';

import 'package:jackbox_client/bloc/jackbox_bloc.dart';

// Lobby implements DrawfulLobbyState
class DrawfulLobby extends StatefulWidget {
  DrawfulLobbyState state;

  DrawfulLobby({this.state});

  @override
  _DrawfulLobbyState createState() => _DrawfulLobbyState(state: state);
}

class _DrawfulLobbyState extends State<DrawfulLobby> {
  DrawfulLobbyState state;

  StreamSubscription _streamSub;
  Stream _prevStream;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  _DrawfulLobbyState({this.state});

  void _listen(Stream<BlocRouteTransition> stream) {
    _streamSub = stream.listen((event) {
      if (event.update) {
        if (event.state is DrawfulLobbyState && event.state != state) {
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

  @override
  Widget build(BuildContext context) {
    final JackboxBloc bloc = Provider.of<JackboxBloc>(context);

    return Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.grey[100],
        body: Container(
                child: Visibility(
                  visible: state != null ? state.allowedToStart : false,
                  child: RaisedButton(
                  child: Text('Start'),
                  onPressed: state != null ? 
                    (state.allowedToStart && state.enoughPlayers ? 
                      () => {
                        bloc.sendEvent(DrawfulStartGameEvent())
                      } : () => {
                        _showToast(context, 'Waiting for additional players')
                      }) : null,
                ),
    )));
  }
}
