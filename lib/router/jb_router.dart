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
import 'package:jackbox_client/ui/drawful/enter_lie.dart';
import 'package:jackbox_client/ui/drawful/choose_lie.dart';
import 'package:jackbox_client/ui/drawful/wait.dart';

class JackboxRouter {
  static Map<String, Function> routeMap = {
    '/': (c, s) => WebInitWidget(),
    '/draw-standalone': (c, s) => DrawfulDrawWidget(standalone: true, state: s),
    SessionLoginState.route: (c, s) => LoginWidget(state: s),
    DrawfulLobbyState.route: (c, s) => DrawfulLobbyWidget(state: s),
    DrawfulDrawingState.route: (c, s) =>
        DrawfulDrawWidget(standalone: false, state: s),
    DrawfulEnterLieState.route: (c, s) => DrawfulEnterLieWidget(state: s),
    DrawfulChooseLieState.route: (c, s) => DrawfulChooseLieWidget(state: s),
    DrawfulWaitState.route: (c, s) => DrawfulWaitWidget(state: s),
  };

  static Route<dynamic> generateRoute(RouteSettings settings) {
    print('Route Settings: $settings');
    if (routeMap.containsKey(settings?.name)) {
      return MaterialPageRoute(
          builder: (c) => routeMap[settings.name](c, settings.arguments));
    } else {
      return MaterialPageRoute(
          builder: (_) => Scaffold(
              body: Center(
                  child: Text('No route defined for ${settings.name}'))));
    }
  }
}
