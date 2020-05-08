library jb_game_handler;

import 'dart:async';
import 'dart:isolate';

import 'package:jackbox_client/model/internal.dart';
import 'package:jackbox_client/model/jackbox.dart';

import 'package:stream_channel/isolate_channel.dart';

typedef GameHandler GameHandlerDef(SendPort port, SessionData meta);

abstract class GameHandler {
  IsolateChannel<IntMsg> _gameChannel;
  StreamSubscription<dynamic> _gameChannelSub;
  SessionData meta;

  GameHandler(SendPort port, SessionData meta) {
    this.meta = meta;

    _gameChannel = new IsolateChannel.connectSend(port);

    _gameChannelSub = _gameChannel.stream.listen(_handleIntMessage, onDone: () {
      resetState();
    });
  }

  void sendIntMessage(IntMsg msg) {
    _gameChannel.sink.add(msg);
  }

  void _handleIntMessage(IntMsg msg) {
    switch (msg.type) {
      case IntMsgType.SESSION:
        if (msg is IntSessionMsg) {
          _handleSessMessage(msg);
        }
        break;
      case IntMsgType.JACKBOX:
        if (msg is IntJackboxMsg) {
          _handleJbMessage(msg);
        }
        break;
      case IntMsgType.UI:
        if (msg is IntUIMsg) {
          _handleUIMessage(msg);
        }
        break;
    }
  }

  void _handleSessMessage(IntSessionMsg msg);

  void _handleJbMessage(IntJackboxMsg msg);

  void _handleUIMessage(IntUIMsg msg);

  bool canHandleStateType(JackboxState state);

  void resetState() {
    _gameChannelSub?.cancel();
    _gameChannel?.sink?.close();

    meta.clear();
    meta = null;
  }
}
