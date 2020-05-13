import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:jackbox_client/bloc/jackbox_bloc.dart';
import 'package:jackbox_client/router/jb_router.dart';

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
      onGenerateRoute: JackboxRouter.generateRoute,
    )
    );
  }
}