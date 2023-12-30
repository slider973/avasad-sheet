import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../home/presentation/manager/init_data_bloc.dart';

class ServiceFactory extends StatelessWidget {
  final Widget child;
  const ServiceFactory({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(providers:  [BlocProvider<InitDataBloc>(create: (context) => InitDataBloc(),)], child: child);
  }
}
