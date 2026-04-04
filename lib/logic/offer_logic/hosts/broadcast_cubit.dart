import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:peer_view/logic/offer_logic/hosts/broadcast_state.dart';

class BroadcastCubit extends Cubit<BroadcastState> {
  BroadcastCubit() : super(BroadcastingInitialState());

  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;

  final int port = 8888;

  Future<void> startBroadcast() async {
    print("====================================================");
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

      _socket!.broadcastEnabled = true;

      _broadcastTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _sendBroadcast(),
      );

      emit(BroadcastingState());
    } catch (e) {
      emit(BroadcastingErrorState(errorMessage: e.toString()));
    }
  }

  // void _sendBroadcast() {
  //   print("Broadcasting");
  //   final message = jsonEncode({
  //     "type": "SCREEN_HOST",
  //     "name": "Leta phone",
  //     "port": 8888,
  //   });

  //   _socket!.send(
  //     utf8.encode(message),
  //     InternetAddress("192.168.146.255"),
  //     port,
  //   );
  // }

  void _sendBroadcast() async {
    print("Broadcasting");

    final ip = await _getLocalIp2();
    if (ip == null) return;

    final broadcastIp = _getBroadcastIp(ip);

    print("IP: $ip");
    print("Broadcast IP: $broadcastIp");

    final message = jsonEncode({
      "type": "SCREEN_HOST",
      "name": "Leta phone",
      "port": 8888,
    });

    _socket!.send(utf8.encode(message), InternetAddress(broadcastIp), port);
  }

  Future<String?> _getLocalIp() async {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          return addr.address;
        }
      }
    }
    return null;
  }

  Future<String?> _getLocalIp2() async {
    for (var interface in await NetworkInterface.list()) {
      // Prefer WiFi interfaces
      if (interface.name.contains('wlan') ||
          interface.name.contains('ap') ||
          interface.name.contains('p2p')) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            print("Using interface: ${interface.name}");
            print("IP: ${addr.address}");
            return addr.address;
          }
        }
      }
    }

    // fallback (if no wlan found)
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          print("Fallback IP: ${addr.address}");
          return addr.address;
        }
      }
    }

    return null;
  }

  String _getBroadcastIp(String ip) {
    final parts = ip.split('.');
    parts[3] = '255';
    return parts.join('.');
  }

  void stopBroadcast() {
    _broadcastTimer?.cancel();
    _socket?.close();

    emit(BroadcastingStoppedState());
  }

  @override
  Future<void> close() {
    _broadcastTimer?.cancel();
    _socket?.close();
    return super.close();
  }
}
