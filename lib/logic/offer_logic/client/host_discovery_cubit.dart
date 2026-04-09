import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:peer_view/logic/offer_logic/client/host_device_modle.dart';
import 'package:peer_view/logic/offer_logic/client/host_discovery_state.dart';

class HostDiscoveryCubit extends Cubit<HostDiscoveryState> {
  HostDiscoveryCubit() : super(HostDiscoveryInitialState());

  RawDatagramSocket? _socket;
  Timer? _cleanupTimer;

  final int port = 8888;
  final Map<String, HostDevice> _hosts = {};

  bool _isRunning = false;

  Future<void> startListening() async {
    if (_isRunning) return; // 🔥 prevent duplicate start
    _isRunning = true;

    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        port,
        reuseAddress: true,
      );

      emit(HostDiscoveringState());

      _socket!.listen((event) {
        print(event);
        if (event != RawSocketEvent.read) return;

        final datagram = _socket!.receive();
        if (datagram == null) return;

        final message = utf8.decode(datagram.data);

        try {
          final data = jsonDecode(message);

          if (data["type"] == "SCREEN_HOST") {
            final ip = datagram.address.address;

            HostDevice? existing = _hosts[ip];

            if (existing != null) {
              existing = HostDevice(
                name: existing.name,
                ip: existing.ip,
                port: existing.port,
                lastSeen: DateTime.now(),
              );
            } else {
              _hosts[ip] = HostDevice(
                name: data["name"],
                ip: ip,
                port: data["port"],
                lastSeen: DateTime.now(),
              );
            }

            _emitHosts();
          }
        } catch (_) {
          // ignore bad packets
        }
      });

      _cleanupTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _removeDeadHosts(),
      );
    } catch (e) {
      _isRunning = false;
      emit(HostDiscoveryErrorState(errorMessage: e.toString()));
    }
  }

  void _emitHosts() {
    emit(HostDiscoveredState(hosts: List.unmodifiable(_hosts.values)));
  }

  void _removeDeadHosts() {
    final now = DateTime.now();

    _hosts.removeWhere((key, host) {
      return now.difference(host.lastSeen).inSeconds > 6;
    });

    _emitHosts();
  }

  Future<void> stopListening() async {
    _isRunning = false;

    _cleanupTimer?.cancel();
    _cleanupTimer = null;

    _socket?.close();
    _socket = null;

    _hosts.clear();

    emit(HostDiscoveryInitialState());
  }

  @override
  Future<void> close() {
    stopListening();
    return super.close();
  }
}

// class HostDiscoveryCubit extends Cubit<HostDiscoveryState> {
//   HostDiscoveryCubit() : super(HostDiscoveryInitialState());

//   RawDatagramSocket? _socket;
//   Timer? _cleanUpTimer;

//   final int port = 8888;

//   final Map<String, HostDevice> _hosts = {};

//   Future<void> startListening() async {
//     try {
//       _socket = await RawDatagramSocket.bind(
//         InternetAddress.anyIPv4,
//         port,
//         reuseAddress: true,
//       );

//       emit(HostDiscoveringState());

//       _socket!.listen((event) {
//         if (event == RawSocketEvent.read) {
//           final datagram = _socket!.receive();

//           if (datagram == null) {
//             return;
//           }

//           final message = utf8.decode(datagram.data);
//           final data = jsonDecode(message);

//           if (data["type"] == "SCREEN_HOST") {
//             final ip = datagram.address.address;
//             final host = HostDevice(
//               name: data['name'],
//               ip: ip,
//               port: data['port'],
//               lastSeen: DateTime.now(),
//             );

//             _hosts[ip] = host;
//           }
//         }
//         print(event);
//         removeDeadHosts();
//         emit(HostDiscoveredState(hosts: _hosts.values.toList()));
//       });

//       // cleanup dead hosts
//       // await removeDeadHosts();
//       // _cleanUpTimer = Timer.periodic(
//       //   const Duration(seconds: 30),
//       //   (_) => removeDeadHosts(),
//       // );
//     } catch (e) {
//       emit(HostDiscoveryErrorState(errorMessage: e.toString()));
//     }
//   }

//   void removeDeadHosts() async {
//     final now = DateTime.now();

//     _hosts.removeWhere((key, host) {
//       return now.difference(host.lastSeen).inSeconds >
//           6; // if silent for >6s remove
//     });

//     emit(HostDiscoveredState(hosts: _hosts.values.toList()));
//   }

//   void stopListening() {
//     _socket?.close();
//     _cleanUpTimer?.cancel();
//   }

//   @override
//   Future<void> close() {
//     _socket?.close();
//     _cleanUpTimer?.cancel();
//     return super.close();
//   }
// }
