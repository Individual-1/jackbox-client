import 'dart:async';
import 'dart:isolate';

import 'package:rxdart/rxdart.dart';
import 'package:stream_channel/isolate_channel.dart';

import 'package:jackbox_client/client/jb_session.dart';
import 'package:jackbox_client/model/jackbox.dart';

class BlocRouteTransition {
  String route;
  Map<String, dynamic> params;

  BlocRouteTransition({this.route, this.params});
}

class JackboxBloc {
  final BehaviorSubject<JackboxState> _jackboxState = BehaviorSubject<JackboxState>.seeded(SessionLoginState(roomCode: "", name: ""));
  final BehaviorSubject<BlocRouteTransition> _jackboxRoute = BehaviorSubject<BlocRouteTransition>.seeded(BlocRouteTransition(route: '/', params: null));

  JackboxSession _jbs;

  ReceivePort _jbsPort;
  IsolateChannel<JackboxState> _jbsChannel;
  StreamSubscription<JackboxState> _jbsChannelSub;

  JackboxBloc() {
    _jbsPort = new ReceivePort();
    _jbsChannel = new IsolateChannel.connectReceive(_jbsPort);

    _jbsChannelSub =
        _jbsChannel.stream.listen(_handleSessionState, onDone: () {
      dispose();
    });

    _jbs = JackboxSession(_jbsPort.sendPort);

    _jackboxState.listen(_handleState);
  }

  // _handleState is the handler for State changes from the UI
  void _handleState(JackboxState state) {
    _jbsChannel.sink.add(state);  
  }

  // _handleSessionState is the handler for State changes from the Jackbox Session object
  void _handleSessionState(JackboxState state) {
    // TODO: Handle new state to set properly
    _jackboxState.add(state);
  }

  Stream<JackboxState> get jackboxState => _jackboxState.stream;

  Stream<BlocRouteTransition> get jackboxRoute => _jackboxRoute.stream;  

  void pushState(JackboxState state) => _jackboxState.sink.add(state);

  void dispose() {
    _jackboxState.close();
    _jackboxRoute.close();

    _jbsChannelSub?.cancel();
    _jbsChannel?.sink?.close();
  }

}