
import 'package:flutter/material.dart';

// Models
import 'package:jackbox_client/model/jackbox.dart';
import 'package:jackbox_client/model/drawful.dart';

// Base UI widgets
import 'package:jackbox_client/ui/webinit.dart';
import 'package:jackbox_client/ui/login.dart';

// Drawful UI widgets
import 'package:jackbox_client/ui/drawful/draw.dart';
import 'package:jackbox_client/ui/drawful/lobby.dart';

class JackboxRouter {
  static Map <String, Function> routeMap = {
    '/': (c, s) => WebInit(),
    '/draw-standalone':  (c, s) => DrawfulDraw(standalone: true, state: s),
    SessionLoginState.route: (c, s) => Login(state: s),

    DrawfulLobbyState.route: (c, s) => DrawfulLobby(state: s),
    DrawfulDrawingState.route: (c, s) => DrawfulDraw(standalone: false, state: s),
    DrawfulEnterLieState.route: null,
    DrawfulChooseLieState.route: null,
  };

  static Route<dynamic> generateRoute(RouteSettings settings) {
    if (routeMap.containsKey(settings.name)) {
      return MaterialPageRoute(builder: (c) => routeMap[settings.name](c, settings.arguments));
    } else {
      return MaterialPageRoute(builder: (_) => Scaffold(
        body: Center(
          child: Text('No route defined for ${settings.name}')
        )
      ));
    }
  }
}