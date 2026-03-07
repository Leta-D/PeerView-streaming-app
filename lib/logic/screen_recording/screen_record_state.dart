import 'package:flutter_webrtc/flutter_webrtc.dart';

abstract class ScreenRecordState {}

class InitialScreenRecordState extends ScreenRecordState {}

class LoadingScreenRecordState extends ScreenRecordState {}

class RecordingScreenRecordState extends ScreenRecordState {
  MediaStream screenMedia;

  RecordingScreenRecordState({required this.screenMedia});
}

class StoppedScreenRecordState extends ScreenRecordState {}

class ErrorScreenRecordState extends ScreenRecordState {
  String errorMessage;

  ErrorScreenRecordState({required this.errorMessage});
}
