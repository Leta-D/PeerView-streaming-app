abstract class HostStreamState {}

class HostStreamInitialState extends HostStreamState {}

class HostStreamStartingState extends HostStreamState {}

class HostStreamRunningState extends HostStreamState {}

class HostStreamingState extends HostStreamState {
  final int connectedClients;
  HostStreamingState({required this.connectedClients});
}

class HostStreamErrorState extends HostStreamState {
  final String errorMessage;
  HostStreamErrorState({required this.errorMessage});
}
