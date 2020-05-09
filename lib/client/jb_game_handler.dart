library jb_game_handler;

import 'dart:async';
import 'dart:isolate';

import 'package:jackbox_client/model/internal.dart';
import 'package:jackbox_client/model/jackbox.dart';

import 'package:stream_channel/isolate_channel.dart';

typedef GameHandler GameHandlerDef(
    SendPort port, SessionData meta, JackboxState initial);

abstract class GameHandler {
  IsolateChannel<IntMsg> _gameChannel;
  StreamSubscription<dynamic> _gameChannelSub;
  SessionData meta;

  JackboxState currentState;

  GameHandler(SendPort port, SessionData meta, JackboxState initial) {
    this.meta = meta;

    this.currentState = initial;

    _gameChannel = new IsolateChannel.connectSend(port);

    _gameChannelSub = _gameChannel.stream.listen(handleIntMessage, onDone: () {
      resetState();
    });
  }

  void sendIntMessage(IntMsg msg) {
    _gameChannel.sink.add(msg);
  }

  void handleIntMessage(IntMsg msg) {
    switch (msg.type) {
      case IntMsgType.SESSION:
        if (msg is IntSessionMsg) {
          handleSessMessage(msg);
        }
        break;
      case IntMsgType.JACKBOX:
        if (msg is IntJackboxMsg) {
          handleJbMessage(msg);
        }
        break;
      default:
        break;
    }
  }

  void handleSessMessage(IntSessionMsg msg);

  void handleJbMessage(IntJackboxMsg msg);

  bool canHandleStateType(JackboxState state);

  void resetState() {
    _gameChannelSub?.cancel();
    _gameChannel?.sink?.close();

    meta.clear();
    meta = null;
  }
}
