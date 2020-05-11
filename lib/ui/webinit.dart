import 'dart:async';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:jackbox_client/bloc/jackbox_bloc.dart';

class WebInit extends StatefulWidget {
  @override
  _WebInitState createState() => _WebInitState();
}

class _WebInitState extends State<WebInit> {
  StreamSubscription _streamSub;
  Stream _prevStream;

  void _listen(Stream<BlocRouteTransition> stream) {
    _streamSub = stream.listen((event) {
      if (event.update) {
      } else {
        Navigator.pushNamed(context, event.route, arguments: event.state);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final JackboxBloc bloc = Provider.of<JackboxBloc>(context);
    if (bloc.jackboxRoute != _prevStream) {
      _streamSub?.cancel();
      _prevStream = bloc.jackboxRoute;
      _listen(bloc.jackboxRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
