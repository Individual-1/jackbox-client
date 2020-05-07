library jb_drawful;

import 'dart:async';
import 'dart:isolate';


import 'package:jackbox_client/model/internal.dart';
import 'package:jackbox_client/model/jackbox.dart';
import 'package:jackbox_client/model/drawful.dart' as state;

import 'package:jackbox_client/client/jb_game_handler.dart';

class DrawfulHandler extends GameHandler {
  DrawfulHandler(SendPort port, SessionData meta) : super(port, meta);

  void _handleIntMessage(IntMsg msg) {
    switch (msg.type) {
      case IntMsgType.SESSION:
        break;
      case IntMsgType.JACKBOX:
        break;
      case IntMsgType.UI:
        break;
    }
  }

/*
// SendImage takes in a serialized json array and sends it to the jackbox server
  void SendImage(String picLineJson) {

    if (this.roomInfo == null || this.ws == null) {
      throw http.ClientException('No connect found, cannot send image to non-existant room');
    }

    // This is dumb but we need to de-serialize the input and put it into our array then re-serialize it
    dynamic picLines = jsonDecode(picLineJson);

    // Map containing arguments to join a jackbox room
    Map<String, dynamic> msg = {
      'name': 'msg',
      'args': [
        {
          'type': 'Action',
          'action': 'SendMessageToRoomOwner',
          'appId': this.roomInfo.appID,
          'roomId': this.roomInfo.roomID,
          'userId': this.userID,
          'message': {
            'setPlayerPicture': true,
            'pictureLines': picLines,
          }
        }
      ]
    };

    String smsg = jsonEncode(msg);

    sendMessage(smsg);
  }
  */
}
