import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:jackbox_client/bloc/jackbox_bloc.dart';

class WebInit extends StatelessWidget {

  WebInit();

  @override
  Widget build(BuildContext context) {
    final JackboxBloc bloc = Provider.of<JackboxBloc>(context);

    return Text('Null State');
  }
}