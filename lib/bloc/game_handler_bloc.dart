library bloc_game_handler;

import 'package:jackbox_client/bloc/jackbox_bloc.dart';
import 'package:jackbox_client/model/jackbox.dart';
import 'package:jackbox_client/model/internal.dart';

typedef GameHandlerBloc GameHandlerBlocDef();

abstract class GameHandlerBloc {
  GameHandlerBloc();

  bool canHandleState(JackboxState state);
  BlocRouteTransition handleState(BlocMsg msg);
}
