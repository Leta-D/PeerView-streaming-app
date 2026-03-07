import 'package:flutter_webrtc/flutter_webrtc.dart';

abstract class ScreenShareState {}

class ScreenShareInitial extends ScreenShareState {}

class ScreenShareLoading extends ScreenShareState {}

class ScreenShareStreaming extends ScreenShareState {
  final RTCPeerConnection peerConnection;
  ScreenShareStreaming(this.peerConnection);
}

class ScreenShareError extends ScreenShareState {
  final String message;
  ScreenShareError(this.message);
}
