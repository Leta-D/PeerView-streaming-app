abstract class ClientConnectState {}

class ClientConnectStateInitial extends ClientConnectState {}

class ClientConnectStateConnecting extends ClientConnectState {}

class ClientConnectStateConnected extends ClientConnectState {}

class ClientConnectStateStreaming extends ClientConnectState {}

class ClientConnectStateError extends ClientConnectState {
  final String errorMessage;

  ClientConnectStateError(this.errorMessage);
}
