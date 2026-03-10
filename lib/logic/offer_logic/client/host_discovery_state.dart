import 'package:peer_view/logic/offer_logic/client/host_device_modle.dart';

abstract class HostDiscoveryState {}

class HostDiscoveryInitialState extends HostDiscoveryState {}

class HostDiscoveringState extends HostDiscoveryState {}

class HostDiscoveredState extends HostDiscoveryState {
  final List<HostDevice> hosts;

  HostDiscoveredState({required this.hosts});
}

class HostDiscoveryErrorState extends HostDiscoveryState {
  String errorMessage;

  HostDiscoveryErrorState({required this.errorMessage});
}
