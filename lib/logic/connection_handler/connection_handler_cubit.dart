import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:peer_view/logic/connection_handler/connection_handler_state.dart';

class ConnectionHandlerCubit extends Cubit<ConnectionHandlerState> {
  ConnectionHandlerCubit() : super(ConnectionHandlerInitialState());

  Future<void> checkConnection() async {
    emit(ConnectionHandlerLoadingState());
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      emit(
        ConnectionHandlerLoadedState(
          isConected: connectivityResult.contains(ConnectivityResult.wifi),
        ),
      );
    } catch (e) {
      emit(ConnectionHandlerErrorState(errorMessage: e.toString()));
    }
  }
}
