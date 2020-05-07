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


  IntSessionMsg() {
    this.type = IntMsgType.SESSION;
  }
}

// IntJackboxMsg essentially serves as a thin wrapper around a serialized JB message
// Take the msg portion and forward it to the Jackbox service
class IntJackboxMsg extends IntMsg {
  dynamic msg;

  IntJackboxMsg({this.msg}) {
    this.type = IntMsgType.JACKBOX;
  }
}

class IntUIMsg extends IntMsg {

  IntUIMsg() {
    this.type = IntMsgType.UI;
  }
}

class SessionData {
  String userID = "";
  String userName = "";
  RoomInfo roomInfo = null;

  SessionData() {
    this.userID = "";
    this.userName = "";
    this.roomInfo = null;
  }

  SessionData.withData({this.userID, this.userName, this.roomInfo});

  void clear() {
    this.userID = "";
    this.userName = "";
    this.roomInfo = null;
  }
}