// GENERATED CODE - DO NOT MODIFY BY HAND

part of drawful;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArgEventBlob _$ArgEventBlobFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['state']);
  return ArgEventBlob(
    state: json['state'] as String,
  );
}

Map<String, dynamic> _$ArgEventBlobToJson(ArgEventBlob instance) =>
    <String, dynamic>{
      'state': instance.state,
    };

AEBLieChoice _$AEBLieChoiceFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['isCensored', 'text']);
  return AEBLieChoice(
    isCensored: json['isCensored'] as bool,
    text: json['text'] as String,
  );
}

Map<String, dynamic> _$AEBLieChoiceToJson(AEBLieChoice instance) =>
    <String, dynamic>{
      'isCensored': instance.isCensored,
      'text': instance.text,
    };

ArgEventBlobRoom _$ArgEventBlobRoomFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['state']);
  return ArgEventBlobRoom(
    state: json['state'] as String,
    platformId: json['platformId'] as String,
  );
}

Map<String, dynamic> _$ArgEventBlobRoomToJson(ArgEventBlobRoom instance) =>
    <String, dynamic>{
      'state': instance.state,
      'platformId': instance.platformId,
    };

AEBRLobby _$AEBRLobbyFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['state', 'lobbyState']);
  return AEBRLobby(
    state: json['state'] as String,
    platformId: json['platformId'] as String,
    isLocal: json['isLocal'] as bool,
    artifact: json['artifact'] as Map<String, dynamic>,
    lobbyState: json['lobbyState'] as String,
    activeContentId: json['activeContentId'],
    formattedActiveContentId: json['formattedActiveContentId'],
    allPlayersHavePortraits: json['allPlayersHavePortraits'] as bool,
  );
}

Map<String, dynamic> _$AEBRLobbyToJson(AEBRLobby instance) => <String, dynamic>{
      'state': instance.state,
      'platformId': instance.platformId,
      'isLocal': instance.isLocal,
      'artifact': instance.artifact,
      'lobbyState': instance.lobbyState,
      'activeContentId': instance.activeContentId,
      'formattedActiveContentId': instance.formattedActiveContentId,
      'allPlayersHavePortraits': instance.allPlayersHavePortraits,
    };

AEBRChooseLie _$AEBRChooseLieFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['state', 'choosingDone', 'choices']);
  return AEBRChooseLie(
    state: json['state'] as String,
    platformId: json['platformId'] as String,
    choosingDone: json['choosingDone'] as bool,
    choices: (json['choices'] as List)
        ?.map((e) =>
            e == null ? null : AEBLieChoice.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$AEBRChooseLieToJson(AEBRChooseLie instance) =>
    <String, dynamic>{
      'state': instance.state,
      'platformId': instance.platformId,
      'choosingDone': instance.choosingDone,
      'choices': instance.choices,
    };

ArgEventBlobCust _$ArgEventBlobCustFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['state']);
  return ArgEventBlobCust(
    state: json['state'] as String,
    playerColors:
        (json['playerColors'] as List)?.map((e) => e as String)?.toList(),
    playerIndex: json['playerIndex'] as int,
    hasPicture: json['hasPicture'] as bool,
    playerName: json['playerName'] as String,
  );
}

Map<String, dynamic> _$ArgEventBlobCustToJson(ArgEventBlobCust instance) =>
    <String, dynamic>{
      'state': instance.state,
      'playerColors': instance.playerColors,
      'playerIndex': instance.playerIndex,
      'hasPicture': instance.hasPicture,
      'playerName': instance.playerName,
    };

AEBCLobby _$AEBCLobbyFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['state', 'isAllowedToStartGame']);
  return AEBCLobby(
    playerColors:
        (json['playerColors'] as List)?.map((e) => e as String)?.toList(),
    state: json['state'] as String,
    playerIndex: json['playerIndex'] as int,
    hasPicture: json['hasPicture'] as bool,
    playerName: json['playerName'] as String,
    lastUGCResult: json['lastUGCResult'],
    canDoUGC: json['canDoUGC'] as bool,
    isAllowedToStartGame: json['isAllowedToStartGame'] as bool,
    canCensor: json['canCensor'] as bool,
    canReport: json['canReport'] as bool,
    history: json['history'] as List,
    canViewAuthor: json['canViewAuthor'] as bool,
  );
}

Map<String, dynamic> _$AEBCLobbyToJson(AEBCLobby instance) => <String, dynamic>{
      'state': instance.state,
      'playerColors': instance.playerColors,
      'playerIndex': instance.playerIndex,
      'hasPicture': instance.hasPicture,
      'playerName': instance.playerName,
      'lastUGCResult': instance.lastUGCResult,
      'canDoUGC': instance.canDoUGC,
      'isAllowedToStartGame': instance.isAllowedToStartGame,
      'canCensor': instance.canCensor,
      'canReport': instance.canReport,
      'history': instance.history,
      'canViewAuthor': instance.canViewAuthor,
    };

AEBCDrawingTime _$AEBCDrawingTimeFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['state', 'prompt']);
  return AEBCDrawingTime(
    playerColors:
        (json['playerColors'] as List)?.map((e) => e as String)?.toList(),
    state: json['state'] as String,
    playerIndex: json['playerIndex'] as int,
    hasPicture: json['hasPicture'] as bool,
    playerName: json['playerName'] as String,
    prompt: json['prompt'] as String,
    receivedDrawing: json['receivedDrawing'] as bool,
  );
}

Map<String, dynamic> _$AEBCDrawingTimeToJson(AEBCDrawingTime instance) =>
    <String, dynamic>{
      'state': instance.state,
      'playerColors': instance.playerColors,
      'playerIndex': instance.playerIndex,
      'hasPicture': instance.hasPicture,
      'playerName': instance.playerName,
      'prompt': instance.prompt,
      'receivedDrawing': instance.receivedDrawing,
    };

AEBCEnterLie _$AEBCEnterLieFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['state', 'isAuthor']);
  return AEBCEnterLie(
    playerColors:
        (json['playerColors'] as List)?.map((e) => e as String)?.toList(),
    state: json['state'] as String,
    playerIndex: json['playerIndex'] as int,
    hasPicture: json['hasPicture'] as bool,
    playerName: json['playerName'] as String,
    canSkipRound: json['canSkipRound'] as bool,
    isAuthor: json['isAuthor'] as bool,
    showError: json['showError'] as bool,
  );
}

Map<String, dynamic> _$AEBCEnterLieToJson(AEBCEnterLie instance) =>
    <String, dynamic>{
      'state': instance.state,
      'playerColors': instance.playerColors,
      'playerIndex': instance.playerIndex,
      'hasPicture': instance.hasPicture,
      'playerName': instance.playerName,
      'canSkipRound': instance.canSkipRound,
      'isAuthor': instance.isAuthor,
      'showError': instance.showError,
    };

AEBCChooseLie _$AEBCChooseLieFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['state', 'entry', 'isAuthor']);
  return AEBCChooseLie(
    playerColors:
        (json['playerColors'] as List)?.map((e) => e as String)?.toList(),
    state: json['state'] as String,
    playerIndex: json['playerIndex'] as int,
    hasPicture: json['hasPicture'] as bool,
    playerName: json['playerName'] as String,
    entry: json['entry'] == null
        ? null
        : AEBLieChoice.fromJson(json['entry'] as Map<String, dynamic>),
    isAuthor: json['isAuthor'] as bool,
    likes: (json['likes'] as List)?.map((e) => e as String)?.toList(),
    canCensor: json['canCensor'] as bool,
    chosen: json['chosen'] == null
        ? null
        : AEBLieChoice.fromJson(json['chosen'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$AEBCChooseLieToJson(AEBCChooseLie instance) =>
    <String, dynamic>{
      'state': instance.state,
      'playerColors': instance.playerColors,
      'playerIndex': instance.playerIndex,
      'hasPicture': instance.hasPicture,
      'playerName': instance.playerName,
      'entry': instance.entry,
      'isAuthor': instance.isAuthor,
      'likes': instance.likes,
      'canCensor': instance.canCensor,
      'chosen': instance.chosen,
    };
