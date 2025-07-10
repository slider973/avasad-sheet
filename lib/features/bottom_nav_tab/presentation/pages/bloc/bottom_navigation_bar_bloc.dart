import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';


part 'bottom_navigation_bar_state.dart';
enum BottomNavigationBarEvent { tab1, tab2, tab3, tab4, tab5 }
class BottomNavigationBarBloc extends Bloc<BottomNavigationBarEvent, int> {
  BottomNavigationBarBloc() : super(0) {
    on<BottomNavigationBarEvent>((event, emit) {
      switch (event) {
        case BottomNavigationBarEvent.tab1:
          emit(0);
          break;
        case BottomNavigationBarEvent.tab2:
          emit(1);
          break;
        case BottomNavigationBarEvent.tab3:
          emit(2);
          break;
        case BottomNavigationBarEvent.tab4:
          emit(3);
          break;
        case BottomNavigationBarEvent.tab5:
          emit(4);
          break;
      }
    });
  }
}
