library drawful;

import 'package:jackbox_client/model/jackbox.dart';

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
  switch(msg.event) {
    case 'RoomBlobChanged':
      break;
    case 'CustomerBlobChanged':
      if (msg.blob is ArgEventBlobMap) {
        ArgEventBlobMap blob = msg.blob;
        ArgEventBlobCust cust = ArgEventBlobCust.fromJson(blob.map);

        switch(cust.state) {
          case 'Lobby':
            return AEBCLobby.fromJson(blob.map);
          case 'Gameplay_DrawingTime':
            return AEBCDrawingTime.fromJson(blob.map);
          case 'Gameplay_EnterLie':
            return AEBCEnterLie.fromJson(blob.map);
          case 'Gameplay_ChooseLie':
            return AEBCChooseLie.fromJson(blob.map);
          case 'Gameplay_Logo':
          case 'Gameplay_LieReceived':
          case 'Gameplay_LyingDone':
          case 'Gameplay_DrawingDone':
            return cust;
          default:
            return cust;
        }
      }
      break;
    default:
      break;
  }
}

class ArgEventBlobCust extends ArgEventBlob {
  List<String> playerColors;
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

  factory ArgEventBlobCust.fromJson(Map<String, dynamic> json) {
    return ArgEventBlobCust(
      playerColors: json['playerColors'],
      state: json['state'],
      playerIndex: json['playerIndex'],
      hasPicture: json['hasPicture'],
      playerName: json['playerName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerColors': null, // This is worthless, no reason to serialize it
      'state': state,
      'playerIndex': playerIndex,
      'hasPicture': hasPicture,
      'playerName': playerName,
    };
  }
}

class AEBCLobby extends ArgEventBlobCust {
  List<String> playerColors;
  String state;
  int playerIndex;
  bool hasPicture;
  String playerName;

  dynamic lastUGCResult;
  bool canDoUGC;
  bool isAllowedToStartGame;
  bool canCensor;
  bool canReport;
  List<dynamic> history;
  bool canViewAuthor;

  AEBCLobby({this.playerColors, this.state, this.playerIndex, this.hasPicture, this.playerName, this.lastUGCResult,
    this.canDoUGC, this.isAllowedToStartGame, this.canCensor, this.canReport, this.history, this.canViewAuthor});

  factory AEBCLobby.fromJson(Map<String, dynamic> json) {
    return AEBCLobby(
      playerColors: null, // Don't care about this, no need to deserialize it
      state: json['state'],
      playerIndex: json['playerIndex'],
      hasPicture: json['hasPicture'],
      playerName: json['playerName'],
      
      lastUGCResult: null, // Useless
      canDoUGC: json['canDoUGC'],
      isAllowedToStartGame: json['isAllowedToStartGame'],
      canCensor: json['canCensor'],
      canReport: json['canReport'],
      history: null, // Useless
      canViewAuthor: json['canViewAuthor'],
    );
  }

    Map<String, dynamic> toJson() {
    return {
      'playerColors': null, // This is worthless, no reason to serialize it
      'state': state,
      'playerIndex': playerIndex,
      'hasPicture': hasPicture,
      'playerName': playerName,
      
      'lastUGCResult': lastUGCResult,
      'canDoUGC': canDoUGC,
      'isAllowedToStartGame': isAllowedToStartGame,
      'canCensor': canCensor,
      'canReport': canReport,
      'history': null,
      'canViewAuthor': canViewAuthor,
    };
    }

}

class AEBCDrawingTime extends ArgEventBlobCust {
  List<String> playerColors;
  String state;
  int playerIndex;
  bool hasPicture;
  String playerName;

  String prompt;
  bool receivedDrawing;

  AEBCDrawingTime({this.playerColors, this.state, this.playerIndex, this.hasPicture, this.playerName,
    this.prompt, this.receivedDrawing});

  factory AEBCDrawingTime.fromJson(Map<String, dynamic> json) {
    return AEBCDrawingTime(
      playerColors: null, // Don't care about this, no need to deserialize it
      state: json['state'],
      playerIndex: json['playerIndex'],
      hasPicture: json['hasPicture'],
      playerName: json['playerName'],
      
      prompt: json['prompt'],
      receivedDrawing: json['receivedDrawing'],
    );
  }

    Map<String, dynamic> toJson() {
    return {
      'playerColors': null, // This is worthless, no reason to serialize it
      'state': state,
      'playerIndex': playerIndex,
      'hasPicture': hasPicture,
      'playerName': playerName,
      
      'prompt': prompt,
      'receivedDrawing': receivedDrawing,
    };
    }

}

class AEBCEnterLie extends ArgEventBlobCust {
  List<String> playerColors;
  String state;
  int playerIndex;
  bool hasPicture;
  String playerName;
  bool canSkipRound;
  bool isAuthor;
  bool showError;

  AEBCEnterLie(
      {this.canSkipRound,
      this.isAuthor,
      this.showError,
      this.playerColors,
      this.state,
      this.playerIndex,
      this.hasPicture,
      this.playerName});

    factory AEBCEnterLie.fromJson(Map<String, dynamic> json) {
    return AEBCEnterLie(
      playerColors: null, // Don't care about this, no need to deserialize it
      state: json['state'],
      playerIndex: json['playerIndex'],
      hasPicture: json['hasPicture'],
      playerName: json['playerName'],
      canSkipRound: json['canSkipRound'],
      isAuthor: json['isAuthor'],
      showError: json['showError'],
    );
  }

    Map<String, dynamic> toJson() {
    return {
      'playerColors': null, // This is worthless, no reason to serialize it
      'state': state,
      'playerIndex': playerIndex,
      'hasPicture': hasPicture,
      'playerName': playerName,
      'canSkipRound': canSkipRound,
      'isAuthor': isAuthor,
      'showError': showError,
    };
  }
}

class AEBCChooseLie extends ArgEventBlobCust {
  List<String> playerColors;
  String state;
  int playerIndex;
  bool hasPicture;
  String playerName;

  Map<String, dynamic> entry; // {'text': yourEntry, 'isCensored': false/true}
  bool isAuthor;
  List<String> likes;
  bool canCensor;

  AEBCChooseLie({this.playerColors, this.state, this.playerIndex, this.hasPicture, this.playerName, 
    this.entry, this.isAuthor, this.likes, this.canCensor});

  factory AEBCChooseLie.fromJson(Map<String, dynamic> json) {
    return AEBCChooseLie(
      playerColors: null, // Don't care about this, no need to deserialize it
      state: json['state'],
      playerIndex: json['playerIndex'],
      hasPicture: json['hasPicture'],
      playerName: json['playerName'],
      
      entry: json['entry'],
      isAuthor: json['isAuthor'],
      likes: json['likes'],
      canCensor: json['canCensor'],
    );
  }

    Map<String, dynamic> toJson() {
    return {
      'playerColors': null, // This is worthless, no reason to serialize it
      'state': state,
      'playerIndex': playerIndex,
      'hasPicture': hasPicture,
      'playerName': playerName,
      
      'entry': entry,
      'isAuthor': isAuthor,
      'likes': likes,
      'canCensor': canCensor,
    };
    }

}
