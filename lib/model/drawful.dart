library drawful;

import 'package:jackbox_client/model/jackbox.dart';

enum GameState {
  MISC_LOBBY,
  GAME_LOGO,
  GAME_DRAWINGTIME,
  GAME_DRAWINGDONE,
  GAME_ENTERLIE,
  GAME_LIEDONE,
  GAME_CHOOSELIE,

}

const Map<String, GameState> StateMap = {
  'Lobby': GameState.MISC_LOBBY,
  'Gameplay_Logo': GameState.GAME_LOGO,
  'Gameplay_DrawingTime': GameState.GAME_DRAWINGTIME,
  'Gameplay_DrawingDone': GameState.GAME_DRAWINGDONE,
  'Gameplay_EnterLie': GameState.GAME_ENTERLIE,
  'Gameplay_LyingDone': GameState.GAME_LIEDONE,
  'Gameplay_ChooseLie': GameState.GAME_CHOOSELIE,
};

// Drawful specific session states to send
abstract class DrawfulState extends JackboxState {}

class DrawfulDrawingState extends DrawfulState {}
class DrawfulDrawingDone extends DrawfulState { Map<String, dynamic> lines;  DrawfulDrawingDone({this.lines}); }
class DrawfulDoneState extends DrawfulState {}
class DrawfulEnterLieState extends DrawfulState {}
class DrawfulChooseLieState extends DrawfulState {}