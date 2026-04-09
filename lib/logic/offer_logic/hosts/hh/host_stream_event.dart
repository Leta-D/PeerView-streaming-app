import 'dart:io';

abstract class HostStreamEvent {}

class StartHostStreamEvent extends HostStreamEvent {}

class StopHostStreamEvent extends HostStreamEvent {}

class ClientConnectedEvent extends HostStreamEvent {
  final WebSocket socket;

  ClientConnectedEvent(this.socket);
}

class OfferReceivedEvent extends HostStreamEvent {
  final WebSocket socket;
  final Map<String, dynamic> data;

  OfferReceivedEvent(this.socket, this.data);
}

class IceReceivedEvent extends HostStreamEvent {
  final Map<String, dynamic> data;

  IceReceivedEvent(this.data);
}
