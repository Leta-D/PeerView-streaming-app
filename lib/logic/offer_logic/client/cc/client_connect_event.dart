abstract class ClientConnectEvent {}

class ConnectToHostEvent extends ClientConnectEvent {
  final String url;

  ConnectToHostEvent(this.url);
}

class AnswerReceivedEvent extends ClientConnectEvent {
  final Map<String, dynamic> data;

  AnswerReceivedEvent(this.data);
}

class IceReceivedEvent extends ClientConnectEvent {
  final Map<String, dynamic> data;

  IceReceivedEvent(this.data);
}

class DisconnectEvent extends ClientConnectEvent {}
