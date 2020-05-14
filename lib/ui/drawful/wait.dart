import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jackbox_client/model/drawful.dart';

import 'package:provider/provider.dart';

import 'package:jackbox_client/bloc/jackbox_bloc.dart';

// Lobby implements DrawfulLobbyState
class DrawfulWaitWidget extends StatefulWidget {
  final DrawfulWaitState state;

  DrawfulWaitWidget({this.state});

  @override
  _DrawfulWaitWidgetState createState() => _DrawfulWaitWidgetState(state: state);
}

class _DrawfulWaitWidgetState extends State<DrawfulWaitWidget> {
  DrawfulWaitState state;

  StreamSubscription _streamSub;
  Stream _prevStream;


  _DrawfulWaitWidgetState({this.state});

  void _listen(Stream<BlocRouteTransition> stream) {
    _streamSub = stream.listen((event) {
      if (event.update) {

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
  Widget build(BuildContext context) {
    final JackboxBloc bloc = Provider.of<JackboxBloc>(context);

    return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Container(
                child: Center(
                child: Text('Please Stand By')
                )));
  }
}
