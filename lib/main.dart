import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:jackbox_client/bloc/jackbox_bloc.dart';
import 'package:jackbox_client/ui/draw.dart';
import 'package:jackbox_client/ui/login.dart';

void main() {
  runApp(JBApp());
}

class JBApp extends StatelessWidget {
  @override
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

}