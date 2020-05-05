library jb_game_handler;

import 'dart:async';
import 'dart:isolate';

import 'jb_data.dart';
import 'sio_msg_type.dart' as mt;

import 'package:stream_channel/isolate_channel.dart';

typedef GameHandler GameHandlerDef(SendPort port, RoomInfo roomInfo);

class GameHandler {
  IsolateChannel<IntraMsg> gameChannel;
  StreamSubscription<dynamic> gameChannelSub;
  RoomInfo roomInfo = null;

  GameHandler(SendPort port, RoomInfo roomInfo) {
    this.roomInfo = roomInfo;

    this.gameChannel = new IsolateChannel.connectSend(port);

    this.gameChannelSub =
        this.gameChannel.stream.listen(handleWSMessage, onDone: () {
      resetState();
    });
  }

  void sendIntraMessage(IntraMsgType type, dynamic msg) {
    gameChannel.sink.add(IntraMsg(type: type, msg: msg));
  }

  void resetState() {
    if (this.gameChannelSub != null) {
      this.gameChannelSub.cancel();
      this.gameChannelSub = null;
    }

    if (this.gameChannel != null) {
      this.gameChannel.sink.close();
      this.gameChannel = null;
    }

    this.roomInfo = null;
  }
}

enum IntraMsgType {
  SESSION,  // Messages between the Session manager and the game handler
  JACKBOX,  // Messages to or from the Jackbox server
  UI,       // Messages to Flutter front-end
}

class IntraMsg {
  IntraMsgType type;
  dynamic msg;

  IntraMsg({this.type, this.msg});
}