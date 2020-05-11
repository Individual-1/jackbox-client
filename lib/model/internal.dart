library internal;

import 'jackbox.dart';

class BlocMsg {
  bool update;
  JackboxState state;

  BlocMsg({this.update, this.state});
}

class SessionData {
  String userId;
  String userName;
  RoomInfo roomInfo;

  SessionData() {
    userId = '';
    userName = '';
    roomInfo = null;
  }

  SessionData.withData({this.userId, this.userName, this.roomInfo});

  void clear() {
    userId = '';
    userName = '';
    roomInfo = null;
  }
}
