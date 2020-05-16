// GENERATED CODE - DO NOT MODIFY BY HAND

part of jackbox;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoomInfo _$RoomInfoFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const [
    'roomid',
    'server',
    'apptag',
    'appid',
    'numAudience',
    'joinAs',
    'requiresPassword'
  ]);
  return RoomInfo(
    roomId: json['roomid'] as String,
    server: json['server'] as String,
    appTag: json['apptag'] as String,
    appId: json['appid'] as String,
    numAudience: json['numAudience'] as int,
    joinAs: json['joinAs'] as String,
    requiresPassword: json['requiresPassword'] as bool,
  );
}

Map<String, dynamic> _$RoomInfoToJson(RoomInfo instance) => <String, dynamic>{
      'roomid': instance.roomId,
      'server': instance.server,
      'apptag': instance.appTag,
      'appid': instance.appId,
      'numAudience': instance.numAudience,
      'joinAs': instance.joinAs,
      'requiresPassword': instance.requiresPassword,
    };

ArgResult _$ArgResultFromJson(Map<String, dynamic> json) {
  return ArgResult(
    roomId: json['roomId'] as String,
    action: json['action'] as String,
    success: json['success'] as bool,
    initial: json['initial'] as bool,
    joinType: json['joinType'] as String,
    userId: json['userId'] as String,
    options: json['options'] as Map<String, dynamic>,
  )..type = json['type'] as String;
}

Map<String, dynamic> _$ArgResultToJson(ArgResult instance) => <String, dynamic>{
      'type': instance.type,
      'roomId': instance.roomId,
      'action': instance.action,
      'success': instance.success,
      'initial': instance.initial,
      'joinType': instance.joinType,
      'userId': instance.userId,
      'options': instance.options,
    };

ArgEvent _$ArgEventFromJson(Map<String, dynamic> json) {
  return ArgEvent(
    roomId: json['roomId'] as String,
    event: json['event'] as String,
    blob: json['blob'] as Map<String, dynamic>,
  )..type = json['type'] as String;
}

Map<String, dynamic> _$ArgEventToJson(ArgEvent instance) => <String, dynamic>{
      'type': instance.type,
      'roomId': instance.roomId,
      'event': instance.event,
      'blob': instance.blob,
    };

ArgActionSendMsg _$ArgActionSendMsgFromJson(Map<String, dynamic> json) {
  return ArgActionSendMsg(
    roomId: json['roomId'] as String,
    appId: json['appId'] as String,
    userId: json['userId'] as String,
    message: json['message'] as Map<String, dynamic>,
  )
    ..type = json['type'] as String
    ..action = json['action'] as String;
}

Map<String, dynamic> _$ArgActionSendMsgToJson(ArgActionSendMsg instance) =>
    <String, dynamic>{
      'type': instance.type,
      'action': instance.action,
      'roomId': instance.roomId,
      'appId': instance.appId,
      'userId': instance.userId,
      'message': instance.message,
    };

ArgActionJoinRoom _$ArgActionJoinRoomFromJson(Map<String, dynamic> json) {
  return ArgActionJoinRoom(
    roomId: json['roomId'] as String,
    appId: json['appId'] as String,
    userId: json['userId'] as String,
    joinType: json['joinType'] as String,
    name: json['name'] as String,
    options: json['options'] as Map<String, dynamic>,
  )
    ..type = json['type'] as String
    ..action = json['action'] as String;
}

Map<String, dynamic> _$ArgActionJoinRoomToJson(ArgActionJoinRoom instance) =>
    <String, dynamic>{
      'type': instance.type,
      'action': instance.action,
      'roomId': instance.roomId,
      'appId': instance.appId,
      'userId': instance.userId,
      'joinType': instance.joinType,
      'name': instance.name,
      'options': instance.options,
    };
