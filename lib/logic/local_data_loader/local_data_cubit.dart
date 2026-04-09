import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:peer_view/logic/local_data_loader/local_data_state.dart';

class LocalDataCubit extends Cubit<LocalDataState> {
  LocalDataCubit() : super(LocalDataInitialState());

  void loadData() async {
    emit(LocalDataLoadingState());
    // final prefs = await SharedP
  }
}
