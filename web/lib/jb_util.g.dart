// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jb_util.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoomInfo _$RoomInfoFromJson(Map<String, dynamic> json) {
  return RoomInfo(
    json['roomid'] as String,
    json['server'] as String,
    json['apptag'] as String,
    json['appid'] as String,
    json['numAudience'] as int,
    json['joinAs'] as String,
    json['requiresPassword'] as bool,
  );
}

Map<String, dynamic> _$RoomInfoToJson(RoomInfo instance) => <String, dynamic>{
      'roomid': instance.roomID,
      'server': instance.server,
      'apptag': instance.appTag,
      'appid': instance.appID,
      'numAudience': instance.numAudience,
      'joinAs': instance.joinAs,
      'requiresPassword': instance.requiresPassword,
    };
