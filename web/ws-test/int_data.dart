library int_data;

enum IntraMsgType {
  SESSION,  // Messages between the Session manager and the game handler
  JACKBOX,  // Messages to or from the Jackbox server
  UI,       // Messages to Flutter front-end
}

class IntraMsg {
  IntraMsgType type;

  IntraMsg({this.type});
}

class IntraSessionMsg extends IntraMsg {


  IntraSessionMsg() {
    this.type = IntraMsgType.SESSION;
  }
}

// IntraJackboxMsg essentially serves as a thin wrapper around a serialized JB message
// Take the msg portion and forward it to the Jackbox service
class IntraJackboxMsg extends IntraMsg {
  dynamic msg;

  IntraJackboxMsg({this.msg}) {
    this.type = IntraMsgType.JACKBOX;
  }
}

class IntraUIMsg extends IntraMsg {

  IntraUIMsg() {
    this.type = IntraMsgType.UI;
  }
}