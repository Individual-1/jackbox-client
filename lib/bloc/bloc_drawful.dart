library bloc_drawful;

import 'package:jackbox_client/bloc/bloc_game_handler.dart';
import 'package:jackbox_client/bloc/jackbox_bloc.dart';
import 'package:jackbox_client/model/internal.dart';
import 'package:jackbox_client/model/jackbox.dart';
import 'package:jackbox_client/model/drawful.dart';

class BlocDrawful extends BlocGameHandler {
  Map<Type, BlocStateHandler> _handledStates;

  BlocDrawful() {
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
    if (_handledStates.containsKey(state.runtimeType)) {
      return true;
    } else {
      return false;
    }
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
        route: msg.state.getRoute(),
        update: msg.update,
        state: msg.state,
      );
    }

    return nextRoute;
  }
}
