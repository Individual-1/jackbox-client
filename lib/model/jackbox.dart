library jackbox;

import 'package:jackbox_client/model/internal.dart';
import 'package:json_annotation/json_annotation.dart';

part 'jackbox.g.dart';

// Events will usually be handled by some message being generated and sent
// String return will be the message to send, empty if taken care of already
typedef String JackboxEventHandler(JackboxEvent event, SessionData meta);

abstract class JackboxEvent {}

// Join room given a roomcode and name
class JackboxLoginEvent extends JackboxEvent {
  String roomCode;
  String name;

  JackboxLoginEvent({this.roomCode, this.name});
}

typedef JackboxState JackboxStateHandler(ArgMsg msg, JackboxState state);

abstract class JackboxState {
  static const String route = '';
  final String iroute = route;
  final Set<Type> allowedEvents = {};
  static const String LOBBY = 'Lobby';

  bool isAllowedEvent(JackboxEvent event) {
    return allowedEvents.contains(event.runtimeType);
  }
}

abstract class SessionState extends JackboxState {}

class SessionLoginState extends SessionState {
  static const String route = '/login';
  final String iroute = route;
  final Set<Type> allowedEvents = {JackboxLoginEvent};

  SessionLoginState();

  @override
  String toString() {
    return '${this.runtimeType}{route: $route}';
  }
}

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
    List<ArgMsg> args = List();

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
  String type = 'Result';
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

  factory ArgResult.fromJson(Map<String, dynamic> json) =>
      _$ArgResultFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ArgResultToJson(this);
}

@JsonSerializable()
class ArgEvent extends ArgMsg {
  String type = 'Event';
  String roomId;
  String event;
  @JsonKey(nullable: true)
  Map<String, dynamic> blob;

  ArgEvent({this.roomId, this.event, this.blob});

  factory ArgEvent.fromJson(Map<String, dynamic> json) =>
      _$ArgEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ArgEventToJson(this);
}

@JsonSerializable()
class ArgActionSendMsg extends ArgMsg {
  String type = 'Action';
  String action = 'SendMessageToRoomOwner';
  String roomId;
  String appId;
  String userId;
  Map<String, dynamic> message;

  ArgActionSendMsg({this.roomId, this.appId, this.userId, this.message});

  factory ArgActionSendMsg.fromJson(Map<String, dynamic> json) =>
      _$ArgActionSendMsgFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ArgActionSendMsgToJson(this);
}

// The JoinRoom action doesn't follow the format of any of the other Action messages
@JsonSerializable()
class ArgActionJoinRoom extends ArgMsg {
  String type = "Action";
  String action = 'JoinRoom';
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

  factory ArgActionJoinRoom.fromJson(Map<String, dynamic> json) =>
      _$ArgActionJoinRoomFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ArgActionJoinRoomToJson(this);
}
