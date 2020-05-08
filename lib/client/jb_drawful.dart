library jb_drawful;

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';


import 'package:jackbox_client/model/internal.dart';
import 'package:jackbox_client/model/jackbox.dart';
import 'package:jackbox_client/model/drawful.dart' as ds;

import 'package:jackbox_client/client/jb_game_handler.dart';

class DrawfulHandler extends GameHandler {
  DrawfulHandler(SendPort port, SessionData meta) : super(port, meta);

  @override
  void _handleUIMessage(IntUIMsg msg) {
    if (msg.state is ds.DrawfulState) {
      switch (msg.state.runtimeType) {
        case ds.DrawfulDrawingDone:
          sendImage((msg.state as ds.DrawfulDrawingDone).lines);
          break;
        default:
          // We don't care about these cases because we don't have to do anything
          break;
      }
    }
  }

  @override
  void _handleJbMessage(IntJackboxMsg msg) {
    Outer parsed;

    parsed = Outer.fromJson(msg.msg);
  }

// sendImage takes in a serialized json array and sends it to the jackbox server
  void sendImage(Map<String, dynamic> lines) {

    if (meta.roomInfo == null) {
      return;
    }

    // Map containing arguments to join a jackbox room
    Map<String, dynamic> msg = {
      'name': 'msg',
      'args': [
        {
          'type': 'Action',
          'action': 'SendMessageToRoomOwner',
          'appId': meta.roomInfo.appID,
          'roomId': meta.roomInfo.roomID,
          'userId': meta.userID,
          'message': {
            'setPlayerPicture': true,
            'pictureLines': lines,
          }
        }
      ]
    };

    String smsg = jsonEncode(msg);

    sendIntMessage(IntJackboxMsg(msg: smsg));
  }

  bool canHandleStateType(JackboxState state) {
    if (state is ds.DrawfulState) {
      return true;
    } else {
      return false;
    }
  }

}
