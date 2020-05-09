library internal;

import 'jackbox.dart';

enum IntMsgType {
  SESSION,  // Messages between the Session manager and the game handler
  JACKBOX,  // Messages to or from the Jackbox server
  UI,       // Messages to Flutter front-end
}

class IntMsg {
  IntMsgType type;

  IntMsg({this.type});
}

class IntSessionMsg extends IntMsg {
  IntSessionAction action;
  dynamic data;

  IntSessionMsg({this.action, this.data}) {
    type = IntMsgType.SESSION;
  }
}

// IntJackboxMsg essentially serves as a thin wrapper around a serialized JB message
// Take the msg portion and forward it to the Jackbox service
class IntJackboxMsg extends IntMsg {
  dynamic msg;

  IntJackboxMsg({this.msg}) {
    type = IntMsgType.JACKBOX;
  }
}

enum IntSessionAction {
  UPDATESTATE, // data = {'process': shouldProcess, 'state': newState}
}

class SessionData {
  String userId = "";
  String userName = "";
  RoomInfo roomInfo = null;

  SessionData() {
    userId = "";
    userName = "";
    roomInfo = null;
  }

  SessionData.withData({this.userId, this.userName, this.roomInfo});

  void clear() {
    userId = "";
    userName = "";
    roomInfo = null;
  }
}
