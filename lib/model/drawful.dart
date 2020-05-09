library drawful;

import 'package:jackbox_client/model/jackbox.dart';
import 'package:json_annotation/json_annotation.dart';

part 'drawful.g.dart';

const Map<String, Type> StateMap = {
  'Gameplay_Logo': DrawfulDoneState,
  'Gameplay_DrawingTime': DrawfulDrawingState,
  'Gameplay_DrawingDone': DrawfulDrawingDoneState,
  'Gameplay_EnterLie': DrawfulEnterLieState,
  'Gameplay_LieReceived': null,
  'Gameplay_LyingDone': DrawfulLyingDoneState,
  'Gameplay_ChooseLie': DrawfulChooseLieState,
};

// Drawful specific session states to send
abstract class DrawfulState extends JackboxState {}

class DrawfulDrawingState extends DrawfulState {}

class DrawfulDrawingDoneState extends DrawfulState {
  Map<String, dynamic> lines;
  DrawfulDrawingDoneState({this.lines});
}

class DrawfulDoneState extends DrawfulState {}

class DrawfulEnterLieState extends DrawfulState {}

class DrawfulLyingDoneState extends DrawfulState {}

class DrawfulChooseLieState extends DrawfulState {}

ArgEventBlob getSpecificBlobType(ArgEvent msg) {
  switch (msg.event) {
    case 'RoomBlobChanged':
      ArgEventBlobRoom room = ArgEventBlobRoom.fromJson(msg.blob);
      switch (room.state) {
        case 'Lobby':
          return AEBRLobby.fromJson(msg.blob);
        case 'Gameplay_ChooseLie':
          return AEBRChooseLie.fromJson(msg.blob);
        case 'Gameplay_DrawingTime':
        case 'Gameplay_EnterLie':
        case 'Gameplay_Logo':
        case 'Gameplay_LieReceived':
        case 'Gameplay_LyingDone':
        case 'Gameplay_DrawingDone':
          return room;
        default:
          return room;
      }
      break;
    case 'CustomerBlobChanged':
      ArgEventBlobCust cust = ArgEventBlobCust.fromJson(msg.blob);
      switch (cust.state) {
        case 'Lobby':
          return AEBCLobby.fromJson(msg.blob);
        case 'Gameplay_DrawingTime':
          return AEBCDrawingTime.fromJson(msg.blob);
        case 'Gameplay_EnterLie':
          return AEBCEnterLie.fromJson(msg.blob);
        case 'Gameplay_ChooseLie':
          return AEBCChooseLie.fromJson(msg.blob);
        case 'Gameplay_Logo':
        case 'Gameplay_LieReceived':
        case 'Gameplay_LyingDone':
        case 'Gameplay_DrawingDone':
          return cust;
        default:
          return cust;
      }
      break;
    default:
      break;
  }

  return null;
}

abstract class ArgEventBlob {}

@JsonSerializable()
class ArgEventBlobRoom extends ArgEventBlob {
  @JsonKey(name: 'state', required: true)
  String state;
  String platformId;

  ArgEventBlobRoom({this.state, this.platformId});

  factory ArgEventBlobRoom.fromJson(Map<String, dynamic> json) =>
      _$ArgEventBlobRoomFromJson(json);

  Map<String, dynamic> toJson() => _$ArgEventBlobRoomToJson(this);
}

@JsonSerializable()
class AEBRLobby extends ArgEventBlobRoom {
  bool isLocal;
  @JsonKey(name: 'artifact', nullable: true)
  Map<String, dynamic> artifact;
  @JsonKey(name: 'lobbyState', required: true)
  String lobbyState;
  @JsonKey(name: 'activeContentId', nullable: true)
  dynamic activeContentId; // What is this even?
  @JsonKey(name: 'formattedActiveContentId', nullable: true)
  dynamic formattedActiveContentId;
  bool allPlayersHavePortraits;

  AEBRLobby({
    String state,
    String platformId,
    this.isLocal,
    this.artifact,
    this.lobbyState,
    this.activeContentId,
    this.formattedActiveContentId,
    this.allPlayersHavePortraits,
  }) : super(state: state, platformId: platformId);

  factory AEBRLobby.fromJson(Map<String, dynamic> json) =>
      _$AEBRLobbyFromJson(json);

  Map<String, dynamic> toJson() => _$AEBRLobbyToJson(this);
}

@JsonSerializable()
class AEBRChooseLie extends ArgEventBlobRoom {
  @JsonKey(name: 'choosingDone', required: true)
  bool choosingDone;
  @JsonKey(name: 'choices', required: true)
  List<AEBRLieChoice> choices;

  AEBRChooseLie({
    String state,
    String platformId,
    this.choosingDone,
    this.choices,
  }) : super(state: state, platformId: platformId);

  factory AEBRChooseLie.fromJson(Map<String, dynamic> json) => _$AEBRChooseLieFromJson(json);

  Map<String, dynamic> toJson() => _$AEBRChooseLieToJson(this);
}

@JsonSerializable()
class AEBRLieChoice {
  @JsonKey(name: 'isCensored', required: true)
  bool isCensored;
  @JsonKey(name: 'text', required: true)
  String text;

  AEBRLieChoice({this.isCensored, this.text});

  factory AEBRLieChoice.fromJson(Map<String, dynamic> json) =>
      _$AEBRLieChoiceFromJson(json);

  Map<String, dynamic> toJson() => _$AEBRLieChoiceToJson(this);
}

@JsonSerializable()
class ArgEventBlobCust extends ArgEventBlob {
  List<String> playerColors;
  @JsonKey(name: 'state', required: true)
  String state;
  int playerIndex;
  bool hasPicture;
  String playerName;

  ArgEventBlobCust(
      {this.playerColors,
      this.state,
      this.playerIndex,
      this.hasPicture,
      this.playerName});

  factory ArgEventBlobCust.fromJson(Map<String, dynamic> json) =>
      _$ArgEventBlobCustFromJson(json);

  Map<String, dynamic> toJson() => _$ArgEventBlobCustToJson(this);
}

@JsonSerializable()
class AEBCLobby extends ArgEventBlobCust {
  @JsonKey(name: 'lastUGCResult', nullable: true)
  dynamic lastUGCResult;
  bool canDoUGC;
  @JsonKey(name: 'isAllowedToStartGame', required: true)
  bool isAllowedToStartGame;
  bool canCensor;
  bool canReport;
  @JsonKey(name: 'history', nullable: true, defaultValue: null)
  List<dynamic> history;
  bool canViewAuthor;

  AEBCLobby(
      {List<String> playerColors,
      String state,
      int playerIndex,
      bool hasPicture,
      String playerName,
      this.lastUGCResult,
      this.canDoUGC,
      this.isAllowedToStartGame,
      this.canCensor,
      this.canReport,
      this.history,
      this.canViewAuthor})
      : super(
            playerColors: playerColors,
            state: state,
            playerIndex: playerIndex,
            hasPicture: hasPicture,
            playerName: playerName);

  factory AEBCLobby.fromJson(Map<String, dynamic> json) =>
      _$AEBCLobbyFromJson(json);

  Map<String, dynamic> toJson() => _$AEBCLobbyToJson(this);
}

@JsonSerializable()
class AEBCDrawingTime extends ArgEventBlobCust {
  @JsonKey(name: 'prompt', required: true)
  String prompt;
  bool receivedDrawing;

  AEBCDrawingTime(
      {List<String> playerColors,
      String state,
      int playerIndex,
      bool hasPicture,
      String playerName,
      this.prompt,
      this.receivedDrawing})
      : super(
            playerColors: playerColors,
            state: state,
            playerIndex: playerIndex,
            hasPicture: hasPicture,
            playerName: playerName);

  factory AEBCDrawingTime.fromJson(Map<String, dynamic> json) =>
      _$AEBCDrawingTimeFromJson(json);

  Map<String, dynamic> toJson() => _$AEBCDrawingTimeToJson(this);
}

@JsonSerializable()
class AEBCEnterLie extends ArgEventBlobCust {
  bool canSkipRound;
  @JsonKey(name: 'isAuthor', required: true)
  bool isAuthor;
  bool showError;

  AEBCEnterLie({
    List<String> playerColors,
    String state,
    int playerIndex,
    bool hasPicture,
    String playerName,
    this.canSkipRound,
    this.isAuthor,
    this.showError,
  }) : super(
            playerColors: playerColors,
            state: state,
            playerIndex: playerIndex,
            hasPicture: hasPicture,
            playerName: playerName);

  factory AEBCEnterLie.fromJson(Map<String, dynamic> json) =>
      _$AEBCEnterLieFromJson(json);

  Map<String, dynamic> toJson() => _$AEBCEnterLieToJson(this);
}

@JsonSerializable()
class AEBCChooseLie extends ArgEventBlobCust {
  @JsonKey(name: 'entry', required: true)
  Map<String, dynamic> entry; // {'text': yourEntry, 'isCensored': false/true}
  @JsonKey(name: 'isAuthor', required: true)
  bool isAuthor;
  @JsonKey(name: 'likes', nullable: true, defaultValue: null)
  List<String> likes;
  bool canCensor;

  AEBCChooseLie(
      {List<String> playerColors,
      String state,
      int playerIndex,
      bool hasPicture,
      String playerName,
      this.entry,
      this.isAuthor,
      this.likes,
      this.canCensor})
      : super(
            playerColors: playerColors,
            state: state,
            playerIndex: playerIndex,
            hasPicture: hasPicture,
            playerName: playerName);

  factory AEBCChooseLie.fromJson(Map<String, dynamic> json) =>
      _$AEBCChooseLieFromJson(json);

  Map<String, dynamic> toJson() => _$AEBCChooseLieToJson(this);
}
