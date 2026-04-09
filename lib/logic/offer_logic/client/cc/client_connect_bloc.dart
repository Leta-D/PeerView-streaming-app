import 'dart:convert';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peer_view/logic/offer_logic/client/cc/client_connect_event.dart';
import 'package:peer_view/logic/offer_logic/client/cc/client_connect_state.dart';

class ClientConnectBloc extends Bloc<ClientConnectEvent, ClientConnectState> {
  ClientConnectBloc() : super(ClientConnectStateInitial()) {
    on<ConnectToHostEvent>(_onConnect);
    on<AnswerReceivedEvent>(_onAnswerReceived);
    on<IceReceivedEvent>(_onIceReceived);
    on<DisconnectEvent>(_onDisconnect);
  }

  WebSocket? _socket;
  RTCPeerConnection? _peerConnection;
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  // ----------------------------
  // 1. Connect to Host
  // ----------------------------
  Future<void> _onConnect(
    ConnectToHostEvent event,
    Emitter<ClientConnectState> emit,
  ) async {
    emit(ClientConnectStateConnecting());

    try {
      await remoteRenderer.initialize();

      _socket = await WebSocket.connect(event.url);

      _socket!.listen((message) {
        final data = jsonDecode(message);

        if (data["type"] == "answer") {
          add(AnswerReceivedEvent(data));
        }

        if (data["type"] == "ice") {
          add(IceReceivedEvent(data));
        }
      });

      await _createPeerConnection();

      emit(ClientConnectStateConnected());

      await _createOffer();
    } catch (e) {
      emit(ClientConnectStateError(e.toString()));
    }
  }

  // ----------------------------
  // 2. Create PeerConnection
  // ----------------------------
  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection({
      "iceServers": [
        {"urls": "stun:stun.l.google.com:19302"},
      ],
    });

    _peerConnection!.onTrack = (event) {
      remoteRenderer.srcObject = event.streams[0];
    };

    _peerConnection!.onIceCandidate = (candidate) {
      _socket?.add(jsonEncode({"type": "ice", "candidate": candidate.toMap()}));
    };
  }

  // ----------------------------
  // 3. Create Offer
  // ----------------------------
  Future<void> _createOffer() async {
    final offer = await _peerConnection!.createOffer();

    await _peerConnection!.setLocalDescription(offer);

    _socket?.add(jsonEncode({"type": "offer", "sdp": offer.sdp}));
  }

  // ----------------------------
  // 4. Receive Answer
  // ----------------------------
  Future<void> _onAnswerReceived(
    AnswerReceivedEvent event,
    Emitter<ClientConnectState> emit,
  ) async {
    final data = event.data;

    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(data["sdp"], "answer"),
    );

    emit(ClientConnectStateStreaming());
  }

  // ----------------------------
  // 5. Handle ICE
  // ----------------------------
  void _onIceReceived(
    IceReceivedEvent event,
    Emitter<ClientConnectState> emit,
  ) {
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
  // 6. Disconnect
  // ----------------------------
  Future<void> _onDisconnect(
    DisconnectEvent event,
    Emitter<ClientConnectState> emit,
  ) async {
    await _peerConnection?.close();
    await _socket?.close();
    await remoteRenderer.dispose();

    emit(ClientConnectStateInitial());
  }
}
