import 'package:flutter/material.dart';
import 'package:jackbox_client/ui/webinit.dart';
import 'package:provider/provider.dart';

import 'package:jackbox_client/bloc/jackbox_bloc.dart';
import 'package:jackbox_client/ui/drawful/draw.dart';
import 'package:jackbox_client/ui/login.dart';

void main() {
  runApp(JBApp());
}

class JBApp extends StatelessWidget {
  @override

  Widget build(BuildContext context) {
      return new MaterialApp(
      title: 'Test',
      initialRoute: '/',
      routes: {
        '/': (context) => WebInit(),
        '/draw': (context) => Draw(),
      },
    );
  }

  /*
  Widget build(BuildContext context) {
    return Provider(
    create: (context) => JackboxBloc(),
    dispose: (context, value) => value.dispose(),
    child: MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => NullInit(),
        '/login': (context) => Login(),
        '/lobby': (context) => Lobby(),
        '/draw': (context) => Draw(),
      }
    )
    );
  }
  */

}