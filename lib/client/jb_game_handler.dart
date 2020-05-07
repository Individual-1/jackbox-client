library jb_game_handler;

import 'dart:async';
import 'dart:isolate';

import 'package:jackbox_client/model/internal.dart';
import 'package:jackbox_client/model/jackbox.dart';

import 'package:stream_channel/isolate_channel.dart';

typedef GameHandler GameHandlerDef(SendPort port, SessionData meta);

abstract class GameHandler {
  IsolateChannel<IntMsg> gameChannel;
  StreamSubscription<dynamic> gameChannelSub;
  SessionData meta;

  GameHandler(SendPort port, SessionData meta) {
    this.meta = meta;

    this.gameChannel = new IsolateChannel.connectSend(port);

    this.gameChannelSub =
        this.gameChannel.stream.listen(_handleIntMessage, onDone: () {
      resetState();
    });
  }

  void _sendIntMessage(IntMsg msg) {
    gameChannel.sink.add(msg);
  }

  void _handleIntMessage(IntMsg msg);

  void resetState() {
    if (this.gameChannelSub != null) {
      this.gameChannelSub.cancel();
      this.gameChannelSub = null;
    }

    if (this.gameChannel != null) {
      this.gameChannel.sink.close();
      this.gameChannel = null;
    }

    this.meta.clear();
    this.meta = null;
  }
}