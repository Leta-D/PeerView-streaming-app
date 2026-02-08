import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:peer_view/logic/permission_handler/permission_handler_state.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandlerCubit extends Cubit<PermissionHandlerState> {
  PermissionHandlerCubit() : super(PermissionHandlerInitialState());

  Future<void> requestCammeraPermission() async {
    emit(PermissionHandlerLoadingState());
    try {
      var status = await Permission.camera.status;
      if (status.isGranted) {
        emit(PermissionHandlerGrantedState());
      } else {
        status = await Permission.camera.request();
      }

      if (status.isGranted) {
        emit(PermissionHandlerGrantedState());
      } else if (status.isDenied) {
        emit(PermissionHandlerDeniedState());
      } else if (status.isPermanentlyDenied) {
        emit(PermissionHandlerPermanentlyDeniedState());
      }
    } catch (e) {
      emit(PermissionHandlerErrorState(errorMessage: e.toString()));
    }
  }
}
