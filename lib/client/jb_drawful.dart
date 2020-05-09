library jb_drawful;

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:jackbox_client/model/internal.dart';
import 'package:jackbox_client/model/jackbox.dart';
import 'package:jackbox_client/model/drawful.dart' as ds;

import 'package:jackbox_client/client/jb_game_handler.dart';

class DrawfulHandler extends GameHandler {
  DrawfulHandler(SendPort port, SessionData meta, JackboxState initial) : super(port, meta, initial);

  @override
  void handleSessMessage(IntSessionMsg msg) {
    switch(msg.action) {
      case IntSessionAction.UPDATESTATE:
        if (msg.data is Map<String, dynamic>) {
          if (msg.data['process']) {

          } else {
            currentState = msg.data['state'];
          }
        }
      break;
      default:
      break;
    }
  }

  @override
  void handleJbMessage(IntJackboxMsg msg) {
    if (currentState is SessionLobbyState) {
      SessionLobbyState lobbyState = currentState;
      // If we're in lobby state then we need to handle lobby updates
      Map<String, dynamic> jmsg = jsonDecode(msg.msg);

      Outer msgp = Outer.fromJson(jmsg);

      for (ArgMsg argm in msgp.args) {
        if (argm is ArgEvent) {
          if (argm.event == "RoomBlobChanged") {
            ds.ArgEventBlob blob = ds.getSpecificBlobType(argm);

            
          } else if (argm.event == "CustomerBlobChanged") {
            ds.ArgEventBlob blob = ds.getSpecificBlobType(argm);

            if (blob is ds.AEBCLobby) {
              if (blob.isAllowedToStartGame != lobbyState.allowedToStart) {
                lobbyState.allowedToStart = blob.isAllowedToStartGame;
                currentState = lobbyState;

                sendIntMessage(IntSessionMsg(action: IntSessionAction.UPDATESTATE, 
                  data: {'process': false, 'state': currentState}));
              }
            }
          }
        }
      }
    } else if (currentState is ds.DrawfulDrawingState) {

    }

  }

// sendImage takes in a serialized json array and sends it to the jackbox server
  void sendImage(Map<String, dynamic> lines) {
    if (meta.roomInfo == null) {
      return;
    }

    // Map containing arguments to send an image
    Map<String, dynamic> msg = {
      'name': 'msg',
      'args': [
        {
          'type': 'Action',
          'action': 'SendMessageToRoomOwner',
          'appId': meta.roomInfo.appId,
          'roomId': meta.roomInfo.roomId,
          'userId': meta.userId,
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
