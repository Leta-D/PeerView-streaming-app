import 'dart:convert';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peer_view/logic/offer_logic/hosts/hh/host_stream_event.dart';
import 'package:peer_view/logic/offer_logic/hosts/hh/host_stream_state.dart';
import 'package:peer_view/logic/screen_recording/screen_record_cubit.dart';
import 'package:peer_view/logic/screen_recording/screen_record_state.dart';

class HostBloc extends Bloc<HostStreamEvent, HostStreamState> {
  final ScreenRecordCubit screenRecordCubit;
  HostBloc(this.screenRecordCubit) : super(HostStreamInitialState()) {
    on<StartHostStreamEvent>(_onStartHost);
    on<ClientConnectedEvent>(_onClientConnected);
    on<OfferReceivedEvent>(_onOfferReceived);
    on<IceReceivedEvent>(_onIceReceived);
    on<StopHostStreamEvent>(_onStopHost);
  }

  HttpServer? _server;
  RTCPeerConnection? _peerConnection;
  // MediaStream? _screenStream;

  // ----------------------------
  // 1. Start WebSocket Server
  // ----------------------------
  Future<void> _onStartHost(
    StartHostStreamEvent event,
    Emitter<HostStreamState> emit,
  ) async {
    emit(HostStreamStartingState());

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);

      print("WebSocket running on 8080");

      _server!.listen((request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final socket = await WebSocketTransformer.upgrade(request);

          add(ClientConnectedEvent(socket));
        }
      });

      emit(HostStreamRunningState());
    } catch (e) {
      emit(HostStreamErrorState(errorMessage: e.toString()));
    }
  }

  // ----------------------------
  // 2. Client Connected
  // ----------------------------
  void _onClientConnected(
    ClientConnectedEvent event,
    Emitter<HostStreamState> emit,
  ) {
    final socket = event.socket;

    print("Client connected");

    socket.listen((message) {
      final data = jsonDecode(message);

      if (data["type"] == "offer") {
        add(OfferReceivedEvent(socket, data));
      }

      if (data["type"] == "ice") {
        add(IceReceivedEvent(data));
      }
    });
  }

  // ----------------------------
  // 3. Handle Offer → Answer
  // ----------------------------
  Future<void> _onOfferReceived(
    OfferReceivedEvent event,
    Emitter<HostStreamState> emit,
  ) async {
    try {
      final socket = event.socket;
      final data = event.data;

      _peerConnection = await createPeerConnection({
        "iceServers": [
          {"urls": "stun:stun.l.google.com:19302"},
        ],
      });

      final currentState = screenRecordCubit.state;

      if (currentState is RecordingScreenRecordState) {
        final stream = currentState.screenMedia;

        for (var track in stream.getTracks()) {
          _peerConnection!.addTrack(track, stream);
        }
      } else {
        emit(HostStreamErrorState(errorMessage: "Screen is not recording"));
      }

      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(data["sdp"], "offer"),
      );

      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      socket.add(jsonEncode({"type": "answer", "sdp": answer.sdp}));

      _peerConnection!.onIceCandidate = (candidate) {
        socket.add(jsonEncode({"type": "ice", "candidate": candidate.toMap()}));
      };

      emit(HostStreamingState(connectedClients: 1));
    } catch (e) {
      emit(HostStreamErrorState(errorMessage: e.toString()));
    }
  }

  // ----------------------------
  // 4. Handle ICE from Client
  // ----------------------------
  void _onIceReceived(IceReceivedEvent event, Emitter<HostStreamState> emit) {
    final data = event.data;

    _peerConnection?.addCandidate(
      RTCIceCandidate(
        data["candidate"]["candidate"],
        data["candidate"]["sdpMid"],
        data["candidate"]["sdpMLineIndex"],
      ),
    );
  }

  // ----------------------------
  // 5. Stop Everything
  // ----------------------------
  Future<void> _onStopHost(
    StopHostStreamEvent event,
    Emitter<HostStreamState> emit,
  ) async {
    await _peerConnection?.close();
    await _server?.close();

    // _screenStream?.dispose();

    emit(HostStreamInitialState());
  }
}
