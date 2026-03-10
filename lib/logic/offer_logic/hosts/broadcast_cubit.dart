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

  void _sendBroadcast() {
    final message = jsonEncode({
      "type": "SCREEN_HOST",
      "name": "Leta phone",
      "port": 8888,
    });

    _socket!.send(
      utf8.encode(message),
      InternetAddress("255.255.255.255"),
      port,
    );
  }

  void _stopBroadcast() {
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
