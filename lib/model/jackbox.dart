library jackbox;

import 'package:dart_json_mapper/dart_json_mapper.dart'
    show JsonMapper, jsonSerializable, JsonProperty, Json;

import 'jackbox.reflectable.dart' show initializeReflectable;

@jsonSerializable
class RoomInfo {
  @JsonProperty(name: 'roomid')
  String roomID;

  @JsonProperty(name: 'server')
  String server;

  @JsonProperty(name: 'apptag')
  String appTag;

  @JsonProperty(name: 'appid')
  String appID;

  @JsonProperty(name: 'numAudience')
  int numAudience;

  @JsonProperty(name: 'joinAs')
  String joinAs;

  @JsonProperty(name: 'requiresPassword')
  bool requiresPassword;
}

@jsonSerializable
class Outer {
  @JsonProperty(name: 'name')
  String name;

  @JsonProperty(name: 'args')
  List<ArgMsg> args;
}

@jsonSerializable
@Json(typeNameProperty: 'typeName')
abstract class ArgMsg {
  @JsonProperty(name: 'type')
  String type;

  @JsonProperty(name: 'roomId')
  String roomID;
}

@jsonSerializable
class ArgResult extends ArgMsg {
  @JsonProperty(name: 'action')
  String action;

  @JsonProperty(name: 'success')
  bool success;

  @JsonProperty(name: 'initial')
  bool initial;

  @JsonProperty(name: 'joinType')
  String joinType;

  @JsonProperty(name: 'userId')
  String userID;

  @JsonProperty(name: 'options')
  ArgResultOptions options;
}

@jsonSerializable
class ArgEvent extends ArgMsg {
  @JsonProperty(name: 'event')
  String event;

  @JsonProperty(name: 'blob')
  ArgEventBlob blob;
}

@jsonSerializable
abstract class ArgResultOptions {
  @JsonProperty(name: 'email')
  String email;

  @JsonProperty(name: 'name')
  String name;

  @JsonProperty(name: 'phone')
  String phone;

  @JsonProperty(name: 'roomcode')
  String roomCode;
}

@jsonSerializable
abstract class ArgEventBlob {
  @JsonProperty(name: 'email')
  String email;

  @JsonProperty(name: 'name')
  String name;

  @JsonProperty(name: 'phone')
  String phone;

  @JsonProperty(name: 'roomcode')
  String roomCode;
}
