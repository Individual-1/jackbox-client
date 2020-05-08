import 'dart:async';
import 'dart:isolate';

import 'package:rxdart/rxdart.dart';
import 'package:stream_channel/isolate_channel.dart';

import 'package:jackbox_client/client/jb_session.dart';
import 'package:jackbox_client/model/jackbox.dart';

class JackboxBloc {
  final BehaviorSubject<JackboxState> _jackboxState = BehaviorSubject<JackboxState>.seeded(SessionLoginState(roomCode: "", name: ""));

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

  void dispose() {
    _jackboxState.close();

    if (_jbsChannelSub != null) {
      _jbsChannelSub.cancel();
      _jbsChannelSub = null;
    }

    if (_jbsChannel != null) {
      _jbsChannel.sink.close();
      _jbsChannel = null;
    }
  }

}