library bloc_drawful;

import 'package:jackbox_client/bloc/game_handler_bloc.dart';
import 'package:jackbox_client/bloc/jackbox_bloc.dart';
import 'package:jackbox_client/model/internal.dart';
import 'package:jackbox_client/model/jackbox.dart';
import 'package:jackbox_client/model/drawful.dart';

class DrawfulBloc extends GameHandlerBloc {
  Map<Type, BlocStateHandler> _handledStates;

  DrawfulBloc() {
    _initHandlerMaps();
  }

  void _initHandlerMaps() {
    _handledStates = {
      DrawfulLobbyState: (m) => _handleDrawfulState(m),
      DrawfulDrawingState: (m) => _handleDrawfulState(m),
      DrawfulWaitState: (m) => _handleDrawfulState(m),
      DrawfulEnterLieState: (m) => _handleDrawfulState(m),
      DrawfulChooseLieState: (m) => _handleDrawfulState(m),
    };
  }

  bool canHandleState(JackboxState state) {
    return _handledStates.containsKey(state.runtimeType);
  }

  BlocRouteTransition handleState(BlocMsg msg) {
    BlocRouteTransition nextRoute;
    
    if (canHandleState(msg.state)) {
      nextRoute = _handledStates[msg.state.runtimeType](msg);
    }

    return nextRoute;
  }

  // We have this handler infra in place in case we need to handle each case differently
  // For routes that don't need it we have this
  BlocRouteTransition _handleDrawfulState(BlocMsg msg) {
    BlocRouteTransition nextRoute;

    if (msg.state is DrawfulState) {
      nextRoute = BlocRouteTransition(
        route: msg.state.iroute,
        update: msg.update,
        state: msg.state,
      );
    }

    return nextRoute;
  }
}
