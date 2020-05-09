library jackbox;

abstract class JackboxState {}

abstract class SessionState extends JackboxState {}

// SessionLoginState is somewhat overloaded
// 1. When neither or only one of the fields is filled, the empty one is invalid
// 2. When both are filled and we recieve it then we attempt a login and invalidate any unusable fields
// 3. If we attempt a login and it is successful, we change state entirely
class SessionLoginState extends SessionState {
  String roomCode;
  String name;
  SessionLoginState({this.roomCode, this.name});
}

class SessionLobbyState extends SessionState {
  bool allowedToStart;
  bool enoughPlayers;
  SessionLobbyState({this.allowedToStart, this.enoughPlayers});
}

const Map<String, Type> StateMap = {
  'Lobby': SessionLobbyState,
};

class RoomInfo {
  String roomID;

  String server;

  String appTag;

  String appID;

  int numAudience;

  String joinAs;

  bool requiresPassword;

  RoomInfo(
      {this.roomID,
      this.server,
      this.appTag,
      this.appID,
      this.numAudience,
      this.joinAs,
      this.requiresPassword});

  factory RoomInfo.fromJson(Map<String, dynamic> json) {
    return RoomInfo(
      roomID: json['roomid'],
      server: json['server'],
      appTag: json['apptag'],
      appID: json['appid'],
      numAudience: json['numAudience'],
      joinAs: json['joinAs'],
      requiresPassword: json['requiresPassword'],
    );
  }
}

class Outer {
  String name;
  List<ArgMsg> args;

  Outer({this.name, this.args});

  @override
  String toString() {
    return toJson().toString();
  }

  factory Outer.fromJson(Map<String, dynamic> json) {
    List<ArgMsg> args = new List();

    if (json.containsKey('args') && json['args'] is List) {
      for (dynamic arg in json['args']) {
        if (arg is Map<String, dynamic>) {
          Map<String, dynamic> argBody = arg;

          if (argBody.containsKey('type')) {
            switch (argBody['type'].toString().toLowerCase()) {
              case 'result':
                args.add(ArgResult.fromJson(arg));
                break;
              case 'event':
                args.add(ArgEvent.fromJson(arg));
                break;
              default:
                break;
            }
          }
        }
      }
    }

    return Outer(
      name: json['name'],
      args: args,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> out = new Map<String, dynamic>();

    out['name'] = name;
    out['args'] = List<Map<String, dynamic>>();

    for (ArgMsg arg in args) {
      (out['args'] as List).add(arg.toJson());
    }

    return out;
  }
}

abstract class ArgMsg {
  String type;
  String roomID;

  String toString() {
    return toJson().toString();
  }

  Map<String, dynamic> toJson();
}

class ArgResult extends ArgMsg {
  final String type = "Result";
  String roomID;
  String action;
  bool success;
  bool initial;
  String joinType;
  String userID;
  ArgResultOptions options;

  ArgResult(
      {this.roomID,
      this.action,
      this.success,
      this.initial,
      this.joinType,
      this.userID,
      this.options});

  factory ArgResult.fromJson(Map<String, dynamic> json) {
    return ArgResult(
      roomID: json['roomId'],
      action: json['action'],
      success: json['success'],
      initial: json['initial'],
      joinType: json['joinType'],
      userID: json['userId'],
      options: null, //TODO: figure out if we care about this
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'roomId': roomID,
      'action': action,
      'success': success,
      'initial': initial,
      'joinType': joinType,
      'userId': userID,
      'options': options?.toJson(),
    };
  }
}

class ArgEvent extends ArgMsg {
  final String type = "Event";
  String roomID;
  String event;
  ArgEventBlob blob;

  ArgEvent({this.roomID, this.event, this.blob});

  factory ArgEvent.fromJson(Map<String, dynamic> json) {
    ArgEventBlob blob;
    Map<String, dynamic> blobBody;

    if (json.containsKey('blob') && json['blob'] is Map<String, dynamic>) {
      blobBody = json['blob'];

      if (blobBody.containsKey('')) {}
    }

    return ArgEvent(
      roomID: json['roomId'],
      event: json['event'],
      blob: ArgEventBlobMap.fromJson(blobBody), // TODO: Find out different blob types
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'roomId': roomID,
      'event': event,
      'blob': blob?.toJson(),
    };
  }
}

class ArgAction extends ArgMsg {
  final String type = "Action";
  String action;
  String roomID;
  String appID;
  String userID;
  ArgActionMsg message;

  ArgAction({this.action, this.roomID, this.appID, this.userID, this.message});

  factory ArgAction.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> msgMap;

    if (json.containsKey('message') &&
        json['message'] is Map<String, dynamic>) {
      msgMap = json['message'];
    }

    return ArgAction(
      action: json['action'],
      roomID: json['roomId'],
      appID: json['appId'],
      userID: json['userId'],
      message: ArgActionMsgMap.fromJson(msgMap), // TODO: Find out different blob types
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'action': action,
      'roomId': roomID,
      'appId': appID,
      'userId': userID,
      'message': message?.toJson(),
    };
  }
}

// The JoinRoom action doesn't follow the format of any of the other Action messages
class ArgActionJoinRoom extends ArgMsg {
  final String type = "Action";
  String action;
  String roomID;
  String appID;
  String userID;
  String joinType;
  String name;
  Map<String, dynamic> options;

  ArgActionJoinRoom({this.action, this.roomID, this.appID, this.userID, this.joinType, this.name, this.options});

  factory ArgActionJoinRoom.fromJson(Map<String, dynamic> json) {
    return ArgActionJoinRoom(
      action: json['action'],
      roomID: json['roomId'],
      appID: json['appId'],
      userID: json['userId'],
      joinType: json['joinType'],
      name: json['name'],
      options: json['options'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'action': action,
      'roomId': roomID,
      'appId': appID,
      'userId': userID,
      'joinType': joinType,
      'name': name,
      'options': options,
    };
  }
}

abstract class ArgResultOptions {
  Map<String, dynamic> toJson();

  String toString() {
    return toJson().toString();
  }
}

class ArgResultOptionsJoinRoom extends ArgResultOptions {
  String email;
  String name;
  String phone;
  String roomCode;

  ArgResultOptionsJoinRoom({this.email, this.name, this.phone, this.roomCode});

  factory ArgResultOptionsJoinRoom.fromJson(Map<String, dynamic> json) {
    return ArgResultOptionsJoinRoom(
      email: json['email'],
      name: json['name'],
      phone: json['phone'],
      roomCode: json['roomCode'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'roomCode': roomCode,
    };
  }
}

abstract class ArgEventBlob {
  Map<String, dynamic> toJson();

  String toString() {
    return toJson().toString();
  }
}

class ArgEventBlobMap extends ArgEventBlob {
  Map<String, dynamic> map;

  ArgEventBlobMap() {
    map = new Map<String, dynamic>();
  }

  factory ArgEventBlobMap.fromJson(Map<String, dynamic> json) {
    ArgEventBlobMap blob = ArgEventBlobMap();
    blob.map.addAll(json);

    return blob;
  }

  @override
  Map<String, dynamic> toJson() {
    return map;
  }
}

abstract class ArgActionMsg {
  Map<String, dynamic> toJson();

  String toString() {
    return toJson().toString();
  }
}

class ArgActionMsgMap extends ArgActionMsg {
  Map<String, dynamic> map;

  ArgActionMsgMap() {
    map = new Map<String, dynamic>();
  }

  factory ArgActionMsgMap.fromJson(Map<String, dynamic> json) {
    ArgActionMsgMap msg = ArgActionMsgMap();
    msg.map.addAll(json);

    return msg;
  }

  @override
  Map<String, dynamic> toJson() {
    return map;
  }
}
