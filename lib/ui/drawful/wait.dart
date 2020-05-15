import 'package:flutter/material.dart';
import 'package:jackbox_client/model/drawful.dart';

// Lobby implements DrawfulLobbyState
class DrawfulWaitWidget extends StatefulWidget {
  final DrawfulWaitState state;

  DrawfulWaitWidget({this.state});

  @override
  _DrawfulWaitWidgetState createState() => _DrawfulWaitWidgetState(state: state);
}

class _DrawfulWaitWidgetState extends State<DrawfulWaitWidget> {
  DrawfulWaitState state;

  _DrawfulWaitWidgetState({this.state});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Container(
                child: Center(
                child: Text('Please Stand By')
                )));
  }
}
