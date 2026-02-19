import 'package:flutter/services.dart';

class ScreenRecordService {
  static const _channel = MethodChannel('screen_record');

  Future<void> start() async {
    await _channel.invokeListMethod('startScreenRecord');
  }

  Future<void> stop() async {
    await _channel.invokeListMethod('stopScreenRecord');
  }
}
