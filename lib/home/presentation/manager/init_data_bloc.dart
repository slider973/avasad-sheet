import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'init_data_event.dart';
part 'init_data_state.dart';

class InitDataBloc extends Bloc<InitDataEvent, InitDataState> {
  InitDataBloc() : super(InitDataInitial()) {
    on<InitDataEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
