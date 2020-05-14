import 'dart:async';

import 'package:jackbox_client/bloc/drawful_bloc.dart';

import 'package:jackbox_client/client/jb_session.dart';
import 'package:jackbox_client/model/jackbox.dart';
import 'package:jackbox_client/model/internal.dart';
import 'package:jackbox_client/bloc/game_handler_bloc.dart';

class BlocRouteTransition {
  String route;
  bool update;
  JackboxState state;

  BlocRouteTransition({this.route, this.update, this.state});
}

typedef BlocRouteTransition BlocStateHandler(BlocMsg msg);

class JackboxBloc {
  JackboxSession _jbs;
  GameHandlerBloc _gh;

  Map<Type, BlocStateHandler> _handledStates;
  Map<Type, String> _handledStateRoutes;
  static final Map<String, GameHandlerBlocDef> _handledGames = {
    // Drawful 2
    '8511cbe0-dfff-4ea9-94e0-424daad072c3': () => DrawfulBloc(),
  };

  StreamSubscription<BlocMsg> _stateSub;
  StreamController<BlocRouteTransition> _routeStream;
  int _routeListenerCount = 0;

  JackboxBloc() {
    _jbs = JackboxSession();

    _initHandlerMaps();

    _routeStream =
        StreamController<BlocRouteTransition>.broadcast(onCancel: () {
      _routeListenerCount -= 1;
    }, onListen: () {
      _routeListenerCount += 1;
    });

    _stateSub = _jbs.stateStream().listen(_handleState, onDone: () {
      dispose();
    });
  }

  void _initHandlerMaps() {
    _handledStates = {
      SessionLoginState: (m) => _handleSessionState(m),
    };
  }

  bool canHandleState(JackboxState state) {
    return _handledStates.containsKey(state.runtimeType);
  }

  // _handleState is the handler for State changes from the session manager
  void _handleState(BlocMsg msg) async {
    BlocRouteTransition nextRoute;

    if (_gh == null) {
      String appId = _jbs.getAppId();

      if (appId != '' && _handledGames.containsKey(appId)) {
        _gh = _handledGames[appId]();
      }
    }

    if (canHandleState(msg.state)) {
      nextRoute = _handledStates[msg.state.runtimeType](msg);
    } else if (_gh != null && _gh.canHandleState(msg.state)) {
      nextRoute = _gh.handleState(msg);
    }

    print('{route: ${nextRoute.route}' +
    ', update: ${nextRoute.update}' +
    ', state: ${nextRoute.state}' +
    '}');
    
    await _waitUntilListeners();
    _routeStream.sink.add(nextRoute);
  }

  BlocRouteTransition _handleSessionState(BlocMsg msg) {
    BlocRouteTransition nextRoute;

    if (msg.state is SessionState) {
      nextRoute = BlocRouteTransition(
        route: msg.state.iroute,
        update: msg.update,
        state: msg.state,
      );
    }

    return nextRoute;
  }

  Future _waitUntilListeners() {
    Duration pollInterval = Duration(milliseconds: 250);
    Completer completer = Completer();

    check() {
      if (_routeListenerCount > 0) {
        completer.complete();
      } else {
        Timer(pollInterval, check);
      }
    }

    check();

    return completer.future;
  }

  void sendEvent(JackboxEvent event) {
    _jbs.sendEvent(event);
  }

  Future<bool> isValidRoom(String roomCode) async {
    bool valid = await _jbs.isValidRoom(roomCode);

    return valid;
  }

  Stream<BlocRouteTransition> get jackboxRoute => _routeStream.stream;

  void dispose() {
    _routeStream.close();

    _stateSub?.cancel();
  }
}
