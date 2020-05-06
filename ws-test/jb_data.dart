library jb_data;

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';

part 'jb_data.g.dart';

class SessionData {
  String userID = "";
  String userName = "";
  RoomInfo roomInfo = null;

  SessionData() {
    this.userID = "";
    this.userName = "";
    this.roomInfo = null;
  }

  SessionData.withData({this.userID, this.userName, this.roomInfo});

  void clear() {
    this.userID = "";
    this.userName = "";
    this.roomInfo = null;
  }
}

abstract class RoomInfo implements Built<RoomInfo, RoomInfoBuilder> {
   @BuiltValueField(wireName: 'roomid')
  final String roomID;

  @BuiltValueField(wireName: 'server')
  final String server;

  @BuiltValueField(wireName: 'apptag')
  final String appTag;

  @BuiltValueField(wireName: 'appid')
  final String appID;

  @BuiltValueField(wireName: 'numAudience')
  final int numAudience;

  @BuiltValueField(wireName: 'joinAs')
  final String joinAs;

  @BuiltValueField(wireName: 'requiresPassword')
  final bool requiresPassword;

  RoomInfo(this.roomID, this.server, this.appTag, this.appID, this.numAudience,
      this.joinAs, this.requiresPassword);

  RoomInfo._();
  factory RoomInfo([void Function(RoomInfoBuilder) updates]) = _$RoomInfo;

  Map<String, dynamic> toJson() {
    return serializers.serializeWith(RoomInfo.serializer, this);
  }

  static RoomInfo fromJson(Map<String, dynamic> json) {
    return serializers.deserializeWith(RoomInfo.serializer, json);
  }

  static Serializer<RoomInfo> get serializer => _$RoomInfoSerializer;
}

class jbWrapper {
  @BuiltValueField(wireName: 'name')
  String name;

  @BuiltValueField(wireName: 'args')
  List<jbMsg> args;
}

abstract class jbMsg {
  String type;
}

class jbMsgResult extends jbMsg {
  String action;
  bool success;
  bool initial;
  String roomID;
  String joinType;
  String userID;
}
