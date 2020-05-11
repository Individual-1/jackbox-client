library drawful;

import 'dart:collection';

import 'package:json_annotation/json_annotation.dart';

import 'package:jackbox_client/model/jackbox.dart';

part 'drawful.g.dart';

abstract class DrawfulEvent extends JackboxEvent {}

class DrawfulStartGameEvent extends DrawfulEvent {}

class DrawfulSubmitDrawingEvent extends DrawfulEvent {
  Map<String, dynamic> lines;

  DrawfulSubmitDrawingEvent({this.lines});
}

class DrawfulSubmitLieEvent extends DrawfulEvent {
  String lie;
  bool usedSuggestion;

  DrawfulSubmitLieEvent({this.lie, this.usedSuggestion});
}

class DrawfulChooseLieEvent extends DrawfulEvent {
  String choice;

  DrawfulChooseLieEvent({this.choice});
}

class DrawfulLikeChoiceEvent extends DrawfulEvent {
  String choice;

  DrawfulLikeChoiceEvent({this.choice});
}

// Drawful specific session states to send
abstract class DrawfulState extends JackboxState {
  static const String GAMEPLAY_LOGO = 'Gameplay_Logo';
  static const String GAMEPLAY_DRAWINGTIME = 'Gameplay_DrawingTime';
  static const String GAMEPLAY_DRAWINGDONE = 'Gameplay_DrawingDone';
  static const String GAMEPLAY_ENTERLIE = 'Gameplay_EnterLie';
  static const String GAMEPLAY_LIERECEIVED = 'Gameplay_LieReceived';
  static const String GAMEPLAY_LYINGDONE = 'Gameplay_LyingDone';
  static const String GAMEPLAY_CHOOSELIE = 'Gameplay_ChooseLie';

  static final Map<String, Type> StateMap = {
    GAMEPLAY_LOGO: DrawfulDoneState,
    GAMEPLAY_DRAWINGTIME: DrawfulDrawingState,
    GAMEPLAY_DRAWINGDONE: DrawfulDrawingDoneState,
    GAMEPLAY_ENTERLIE: DrawfulEnterLieState,
    GAMEPLAY_LIERECEIVED: null,
    GAMEPLAY_LYINGDONE: DrawfulLyingDoneState,
    GAMEPLAY_CHOOSELIE: DrawfulChooseLieState,
  };
}

class DrawfulLobbyState extends DrawfulState {
  final String route = '/drawful/lobby';
  bool allowedToStart;
  bool enoughPlayers;
  bool startGame;
  bool postGame;

  DrawfulLobbyState(
      {this.allowedToStart, this.enoughPlayers, this.startGame, this.postGame});

  factory DrawfulLobbyState.From(DrawfulLobbyState state) {
    return DrawfulLobbyState(
        allowedToStart: state.allowedToStart,
        enoughPlayers: state.enoughPlayers);
  }
}

// Embed a lobbystate class so we can populate it if we need to go back to lobby after drawing
class DrawfulDrawingState extends DrawfulState {
  final String route = '/drawful/draw';
  String prompt;
  DrawfulLobbyState lobbyState;

  DrawfulDrawingState({this.prompt, this.lobbyState});

  factory DrawfulDrawingState.From(DrawfulDrawingState state) {
    return DrawfulDrawingState(
      prompt: state.prompt,
      lobbyState: state.lobbyState != null
          ? DrawfulLobbyState.From(state.lobbyState)
          : null,
    );
  }
}

class DrawfulDrawingDoneState extends DrawfulState {}

class DrawfulDoneState extends DrawfulState {}

class DrawfulEnterLieState extends DrawfulState {
  final String route = '/drawful/enterlie';
  String lie;
  bool useSuggestion;
  bool isAuthor;

  DrawfulEnterLieState({this.lie, this.useSuggestion, this.isAuthor});

  factory DrawfulEnterLieState.From(DrawfulEnterLieState state) {
    return DrawfulEnterLieState(
      lie: state.lie,
      useSuggestion: state.useSuggestion,
      isAuthor: state.isAuthor,
    );
  }
}

class DrawfulLyingDoneState extends DrawfulState {}

class DrawfulChooseLieState extends DrawfulState {
  final String route = '/drawful/chooselie';
  HashSet<String> choices;
  String myEntry;
  HashSet<String> likes;
  String chosen;
  bool isAuthor;

  DrawfulChooseLieState(
      {this.choices, this.myEntry, this.likes, this.chosen, this.isAuthor});

  factory DrawfulChooseLieState.From(DrawfulChooseLieState state) {
    HashSet<String> choices = new HashSet<String>();
    HashSet<String> likes = new HashSet<String>();

    if (state.choices != null) {
      choices.addAll(state.choices);
    }

    if (state.likes != null) {
      likes.addAll(state.likes);
    }

    return DrawfulChooseLieState(
      choices: choices,
      myEntry: state.myEntry,
      likes: likes,
      chosen: state.chosen,
      isAuthor: state.isAuthor,
    );
  }
}

// This isn't explicity a valid state, but a generic for when we are waiting for something to happen
class DrawfulWaitState extends DrawfulState {
  final String route = '/drawful/wait';
}

ArgEventBlob getSpecificBlobType(ArgEvent msg) {
  switch (msg.event) {
    case 'RoomBlobChanged':
      ArgEventBlobRoom room = ArgEventBlobRoom.fromJson(msg.blob);
      switch (room.state) {
        case JackboxState.LOBBY:
          return AEBRLobby.fromJson(msg.blob);
        case DrawfulState.GAMEPLAY_CHOOSELIE:
          return AEBRChooseLie.fromJson(msg.blob);
        case DrawfulState.GAMEPLAY_DRAWINGTIME:
        case DrawfulState.GAMEPLAY_ENTERLIE:
        case DrawfulState.GAMEPLAY_LOGO:
        case DrawfulState.GAMEPLAY_LIERECEIVED:
        case DrawfulState.GAMEPLAY_LYINGDONE:
        case DrawfulState.GAMEPLAY_DRAWINGDONE:
          return room;
        default:
          return room;
      }
      break;
    case 'CustomerBlobChanged':
      ArgEventBlobCust cust = ArgEventBlobCust.fromJson(msg.blob);
      switch (cust.state) {
        case JackboxState.LOBBY:
          return AEBCLobby.fromJson(msg.blob);
        case DrawfulState.GAMEPLAY_DRAWINGTIME:
          return AEBCDrawingTime.fromJson(msg.blob);
        case DrawfulState.GAMEPLAY_ENTERLIE:
          return AEBCEnterLie.fromJson(msg.blob);
        case DrawfulState.GAMEPLAY_CHOOSELIE:
          return AEBCChooseLie.fromJson(msg.blob);
        case DrawfulState.GAMEPLAY_LOGO:
        case DrawfulState.GAMEPLAY_LIERECEIVED:
        case DrawfulState.GAMEPLAY_LYINGDONE:
        case DrawfulState.GAMEPLAY_DRAWINGDONE:
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

@JsonSerializable()
class ArgEventBlob {
  @JsonKey(name: 'state', required: true)
  String state;

  ArgEventBlob({this.state});
}

@JsonSerializable()
class AEBLieChoice {
  @JsonKey(name: 'isCensored', required: true)
  bool isCensored;
  @JsonKey(name: 'text', required: true)
  String text;

  AEBLieChoice({this.isCensored, this.text});

  factory AEBLieChoice.fromJson(Map<String, dynamic> json) =>
      _$AEBLieChoiceFromJson(json);

  Map<String, dynamic> toJson() => _$AEBLieChoiceToJson(this);
}

@JsonSerializable()
class ArgEventBlobRoom extends ArgEventBlob {
  String platformId;

  ArgEventBlobRoom({String state, this.platformId}) : super(state: state);

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
  List<AEBLieChoice> choices;

  AEBRChooseLie({
    String state,
    String platformId,
    this.choosingDone,
    this.choices,
  }) : super(state: state, platformId: platformId);

  factory AEBRChooseLie.fromJson(Map<String, dynamic> json) =>
      _$AEBRChooseLieFromJson(json);

  Map<String, dynamic> toJson() => _$AEBRChooseLieToJson(this);
}

@JsonSerializable()
class ArgEventBlobCust extends ArgEventBlob {
  List<String> playerColors;
  int playerIndex;
  bool hasPicture;
  String playerName;

  ArgEventBlobCust(
      {String state,
      this.playerColors,
      this.playerIndex,
      this.hasPicture,
      this.playerName})
      : super(state: state);

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
  AEBLieChoice entry;
  @JsonKey(name: 'isAuthor', required: true)
  bool isAuthor;
  @JsonKey(name: 'likes', nullable: true, defaultValue: null)
  List<String> likes;
  bool canCensor;
  @JsonKey(name: 'chosen', nullable: true, defaultValue: null)
  AEBLieChoice chosen;

  AEBCChooseLie(
      {List<String> playerColors,
      String state,
      int playerIndex,
      bool hasPicture,
      String playerName,
      this.entry,
      this.isAuthor,
      this.likes,
      this.canCensor,
      this.chosen})
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
