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
  dynamic blob;

  IntSessionMsg({this.action, this.blob}) {
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

class IntUIMsg extends IntMsg {
  JackboxState state;

  IntUIMsg({this.state}) {
    type = IntMsgType.UI;
  }
}

enum IntSessionAction {
  PLACEHOLDER,
}

class SessionData {
  String userID = "";
  String userName = "";
  RoomInfo roomInfo = null;

  SessionData() {
    userID = "";
    userName = "";
    roomInfo = null;
  }

  SessionData.withData({this.userID, this.userName, this.roomInfo});

  void clear() {
    userID = "";
    userName = "";
    roomInfo = null;
  }
}
