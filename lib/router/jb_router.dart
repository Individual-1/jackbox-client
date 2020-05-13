
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
    '/': () => { WebInit() },
    '/draw-standalone': () => { DrawfulDraw(standalone: true) },
    SessionLoginState.route: () => { Login() },

    DrawfulLobbyState.route: () => { DrawfulLobby() },
    DrawfulDrawingState.route: () => { DrawfulDraw(standalone: false) },
    DrawfulEnterLieState.route: () => { },
    DrawfulChooseLieState.route: () => { },
  };

  static Route<dynamic> generateRoute(RouteSettings settings) {
    if (routeMap.containsKey(settings.name)) {
      return MaterialPageRoute(builder: routeMap[settings.name]);
    } else {
      return MaterialPageRoute(builder: (_) => Scaffold(
        body: Center(
          child: Text('No route defined for ${settings.name}')
        )
      ));
    }
  }
}