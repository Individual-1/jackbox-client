import 'package:flutter/material.dart';
import 'package:jackbox_client/model/drawful.dart';
import 'package:jackbox_client/ui/drawful/choose_lie.dart';
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

class DebugApp extends StatelessWidget {
    @override
  Widget build(BuildContext context) {
    List<String> choices = List<String>();
    choices.add('test');
    choices.add('test2');
    choices.add('test3');
    DrawfulChooseLieState state = DrawfulChooseLieState(
      chosen: '',
      choices: choices,
      myEntry: 'test3',
      likes: List<String>(),
      isAuthor: true,
      );

    return Provider(
    create: (context) => JackboxBloc(),
    dispose: (context, value) => value.dispose(),
    child: MaterialApp(
      home: DrawfulChooseLieWidget(state: state),
    )
    );
  }
}