library jackbox;

import 'dart:collection';

import 'package:json_annotation/json_annotation.dart';

part 'jackbox.g.dart';

abstract class JackboxState {
  static const String LOBBY = 'Lobby';
}

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
  bool startGame;
  bool postGame;

  SessionLobbyState({this.allowedToStart, this.enoughPlayers, this.startGame, this.postGame});

  factory SessionLobbyState.From(SessionLobbyState state) {
    return SessionLobbyState(
      allowedToStart: state.allowedToStart,
      enoughPlayers: state.enoughPlayers
      );
  }
}

const Map<String, Type> StateMap = {
  'Lobby': SessionLobbyState,
};

@JsonSerializable()
class RoomInfo {
  @JsonKey(name: 'roomid', required: true)
  String roomId;
  @JsonKey(name: 'server', required: true)
  String server;
  @JsonKey(name: 'apptag', required: true)
  String appTag;
  @JsonKey(name: 'appid', required: true)
  String appId;
  @JsonKey(name: 'numAudience', required: true)
  int numAudience;
  @JsonKey(name: 'joinAs', required: true)
  String joinAs;
  @JsonKey(name: 'requiresPassword', required: true)
  bool requiresPassword;

  RoomInfo(
      {this.roomId,
      this.server,
      this.appTag,
      this.appId,
      this.numAudience,
      this.joinAs,
      this.requiresPassword});

  factory RoomInfo.fromJson(Map<String, dynamic> json) =>
      _$RoomInfoFromJson(json);

  Map<String, dynamic> toJson() => _$RoomInfoToJson(this);
}

class Outer {
  final String name = 'msg';
  List<ArgMsg> args;

  Outer({this.args});

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
  String roomId;

  String toString() {
    return toJson().toString();
  }

  Map<String, dynamic> toJson();
}

@JsonSerializable()
class ArgResult extends ArgMsg {
  final String type = 'Result';
  String roomId;
  String action;
  bool success;
  bool initial;
  String joinType;
  String userId;
  @JsonKey(name: 'options', nullable: true, defaultValue: null)
  Map<String, dynamic> options;

  ArgResult(
      {this.roomId,
      this.action,
      this.success,
      this.initial,
      this.joinType,
      this.userId,
      this.options});

  factory ArgResult.fromJson(Map<String, dynamic> json) => _$ArgResultFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ArgResultToJson(this);
}

@JsonSerializable()
class ArgEvent extends ArgMsg {
  final String type = 'Event';
  String roomId;
  String event;
  Map<String, dynamic> blob;

  ArgEvent({this.roomId, this.event, this.blob});

  factory ArgEvent.fromJson(Map<String, dynamic> json) => _$ArgEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ArgEventToJson(this);
}

@JsonSerializable()
class ArgActionSendMsg extends ArgMsg {
  final String type = 'Action';
  final String action = 'SendMessageToRoomOwner';
  String roomId;
  String appId;
  String userId;
  Map<String, dynamic> message;

  ArgActionSendMsg({this.roomId, this.appId, this.userId, this.message});

  factory ArgActionSendMsg.fromJson(Map<String, dynamic> json) => _$ArgActionSendMsgFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ArgActionSendMsgToJson(this);
}

// The JoinRoom action doesn't follow the format of any of the other Action messages
@JsonSerializable()
class ArgActionJoinRoom extends ArgMsg {
  final String type = 'Action';
  final String action = 'JoinRoom';
  String roomId;
  String appId;
  String userId;
  String joinType;
  String name;
  Map<String, dynamic> options;

  ArgActionJoinRoom(
      {this.roomId,
      this.appId,
      this.userId,
      this.joinType,
      this.name,
      this.options});

  factory ArgActionJoinRoom.fromJson(Map<String, dynamic> json) => _$ArgActionJoinRoomFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ArgActionJoinRoomToJson(this);
}
