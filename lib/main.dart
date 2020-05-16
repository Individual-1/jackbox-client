import 'package:flutter/material.dart';
import 'package:jackbox_client/model/jackbox.dart';
import 'package:provider/provider.dart';

import 'package:jackbox_client/bloc/jackbox_bloc.dart';
import 'package:jackbox_client/router/jb_router.dart';
import 'package:jackbox_client/ui/drawful/draw.dart';

void main() {
  runApp(JBApp());
}

class JBApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Provider(
    create: (context) => JackboxBloc(navigatorKey: navigatorKey),
    dispose: (context, value) => value.dispose(),
    child: MaterialApp(
      title: 'Jackbox Client',
      navigatorKey: navigatorKey,
      initialRoute: SessionLoginState.route,
      onGenerateRoute: JackboxRouter.generateRoute,
    )
    );
  }
}

class DrawfulCanvasApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drawful Canvas',
      home: DrawfulDrawWidget(standalone: true, state: null)
    );
  }
}