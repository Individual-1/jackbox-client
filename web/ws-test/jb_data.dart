library jb_data;

import 'package:json_annotation/json_annotation.dart';

part 'jb_data.g.dart';

@JsonSerializable()
class RoomInfo {
  @JsonKey(name: 'roomid', nullable: false)
  final String roomID;

  @JsonKey(name: 'server', nullable: false)
  final String server;

  @JsonKey(name: 'apptag', nullable: false)
  final String appTag;

  @JsonKey(name: 'appid', nullable: false)
  final String appID;

  @JsonKey(name: 'numAudience', nullable: false)
  final int numAudience;

  @JsonKey(name: 'joinAs', nullable: false)
  final String joinAs;

  @JsonKey(name: 'requiresPassword', nullable: false)
  final bool requiresPassword;

  RoomInfo(this.roomID, this.server, this.appTag, this.appID, this.numAudience,
      this.joinAs, this.requiresPassword);

  factory RoomInfo.fromJson(Map<String, dynamic> json) =>
      _$RoomInfoFromJson(json);

  Map<String, dynamic> toJson() => _$RoomInfoToJson(this);
}
