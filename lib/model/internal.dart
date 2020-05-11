library internal;

import 'jackbox.dart';

class SessionData {
  String userId = '';
  String userName = '';
  RoomInfo roomInfo = null;

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
