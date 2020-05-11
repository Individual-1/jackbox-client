library jb_game_handler;

import 'dart:async';

import 'package:jackbox_client/model/internal.dart';
import 'package:jackbox_client/model/jackbox.dart';

typedef GameHandler GameHandlerDef();

abstract class GameHandler {
  GameHandler() {}
  
  bool canHandleEvent(JackboxEvent event);
  String handleEvent(JackboxEvent event, SessionData meta);

  bool canHandleState(JackboxState state);
  JackboxState handleState(ArgMsg msg, JackboxState state);
}
