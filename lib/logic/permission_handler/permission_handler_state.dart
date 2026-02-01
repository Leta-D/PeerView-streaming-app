abstract class PermissionHandlerState {}

class PermissionHandlerInitialState extends PermissionHandlerState {}

class PermissionHandlerLoadingState extends PermissionHandlerState {}

class PermissionHandlerGrantedState extends PermissionHandlerState {}

class PermissionHandlerDeniedState extends PermissionHandlerState {}

class PermissionHandlerPermanentlyDeniedState extends PermissionHandlerState {}

class PermissionHandlerErrorState extends PermissionHandlerState {
  final String errorMessage;

  PermissionHandlerErrorState({required this.errorMessage});
}
