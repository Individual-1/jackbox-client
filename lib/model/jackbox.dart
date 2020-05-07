library jackbox;

//import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'jackbox.freezed.dart';
part 'jackbox.g.dart';

@freezed
abstract class RoomInfo with _$RoomInfo {
  @JsonSerializable()
  const factory RoomInfo(
    @JsonKey(name: 'roomid') String roomID,
    @JsonKey(name: 'server') String server,
    @JsonKey(name: 'apptag') String appTag,
    @JsonKey(name: 'appid') String appID,
    @JsonKey(name: 'numAudience') int numAudience,
    @JsonKey(name: 'joinAs') String joinAs,
    @JsonKey(name: 'requiresPassword') bool requiresPassword,
  ) = _RoomInfo;

  factory RoomInfo.fromJson(Map<String, dynamic> json) =>
      _$RoomInfoFromJson(json);
}

@freezed
abstract class Outer with _$Outer {
  @JsonSerializable()
  const factory Outer(
    @JsonKey(name: 'name') String name,
    @JsonKey(name: 'args') List<ArgMsg> args,
  ) = _Outer;

  factory Outer.fromJson(Map<String, dynamic> json) => _$OuterFromJson(json);
}

@freezed
abstract class ArgMsg with _$ArgMsg {
  @JsonSerializable()
  const factory ArgMsg.result(
    @JsonKey(name: 'type') String type,
    @JsonKey(name: 'action') String action,
    @JsonKey(name: 'success') bool success,
    @JsonKey(name: 'initial') bool initial,
    @JsonKey(name: 'roomId') String roomID,
    @JsonKey(name: 'joinType') String joinType,
    @JsonKey(name: 'userId') String userID,
    @JsonKey(name: 'options') ArgResultOptions options,
  ) = ArgResult;

  @JsonSerializable()
  const factory ArgMsg.event(
    @JsonKey(name: 'type') String type,
    @JsonKey(name: 'roomId') String roomID,
    @JsonKey(name: 'event') String event,
    @JsonKey(name: 'blob') ArgEventBlob blob,
  ) = ArgEvent;

  factory ArgMsg.fromJson(Map<String, dynamic> json) => _$ArgMsgFromJson(json);
}

@freezed
abstract class ArgResultOptions with _$ArgResultOptions {
  @JsonSerializable()
  const factory ArgResultOptions(
    @JsonKey(name: 'email') String email,
    @JsonKey(name: 'name') String name,
    @JsonKey(name: 'phone') String phone,
    @JsonKey(name: 'roomcode') String roomCode,
  ) = _ArgResultOptions;

  factory ArgResultOptions.fromJson(Map<String, dynamic> json) =>
      _$ArgResultOptionsFromJson(json);
}

@freezed
abstract class ArgEventBlob with _$ArgEventBlob {
  @JsonSerializable()
  const factory ArgEventBlob(
    @JsonKey(name: 'email') String email,
    @JsonKey(name: 'name') String name,
    @JsonKey(name: 'phone') String phone,
    @JsonKey(name: 'roomcode') String roomCode,
  ) = _ArgEventBlob;

  factory ArgEventBlob.fromJson(Map<String, dynamic> json) =>
      _$ArgEventBlobFromJson(json);
}