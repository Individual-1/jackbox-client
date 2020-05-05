library jb_drawful;

import 'dart:async';
import 'dart:isolate';

import 'jb_game_handler.dart';
import 'jb_data.dart';
import 'jb_state_drawful.dart' as state;

class DrawfulHandler extends GameHandler {

DrawfulHandler(SendPort port, RoomInfo roomInfo) : super(port, roomInfo);

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