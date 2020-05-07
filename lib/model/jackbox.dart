library jackbox;

class RoomInfo {
  String roomID;

  String server;

  String appTag;

  String appID;

  int numAudience;

  String joinAs;

  bool requiresPassword;

  RoomInfo({this.roomID, this.server, this.appTag, this.appID, 
    this.numAudience, this.joinAs, this.requiresPassword});

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

  factory Outer.fromJson(Map<String, dynamic> json) {
    List<ArgMsg> args = new List();

    if (json.containsKey('args') && json['args'] is List) {
      for (dynamic arg in json['args']) {
        if (!(arg is Map<String, dynamic>)) {
          continue;
        }

        Map<String, dynamic> argBody = arg as Map<String, dynamic>;

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

    return Outer(
      name: json['name'],
      args: args,
    );
  }
}

abstract class ArgMsg {
  String type;
  String roomID;
}

class ArgResult extends ArgMsg {
  String type;
  String roomID;
  String action;
  bool success;
  bool initial;
  String joinType;
  String userID;
  ArgResultOptions options;

  ArgResult({this.type, this.roomID, this.action, this.success, this.initial,
    this.joinType, this.userID, this.options});

  factory ArgResult.fromJson(Map<String, dynamic> json) {
    return ArgResult(
      type: json['type'],
      roomID: json['roomId'],
      action: json['action'],
      success: json['success'],
      initial: json['initial'],
      joinType: json['joinType'],
      userID: json['userId'],
      options: null, //TODO: figure out if we care about this
    );
  }
}

class ArgEvent extends ArgMsg {
  String type;
  String roomID;
  String event;
  ArgEventBlob blob;

  ArgEvent({this.type, this.roomID, this.event, this.blob});

  factory ArgEvent.fromJson(Map<String, dynamic> json) {
    ArgEventBlob blob;

    if (json.containsKey('blob') && json['blob'] is Map<String, dynamic>) {
      Map<String, dynamic> blobBody = json['blob'] as Map<String, dynamic>;

      if (blobBody.containsKey('')) {

      }
  }

    return ArgEvent(
      type: json['type'],
      roomID: json['roomId'],
      event: json['event'],
      blob: blob, // TODO: Find out different blob types
    );
  }
}

abstract class ArgResultOptions {
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
}

abstract class ArgEventBlob {
}

class ArgEventBlobRoom extends ArgEventBlob {

  ArgEventBlobRoom();

  factory ArgEventBlobRoom.fromJson(Map<String, dynamic> json) {
    return ArgEventBlobRoom();
  }
}
