enum ScreenRecordStatus {
  idle,
  requestingPermission,
  recording,
  stopped,
  error,
}

class ScreenRecordState {
  final ScreenRecordStatus status;
  final String? message;

  const ScreenRecordState({required this.status, this.message});

  factory ScreenRecordState.initial() {
    return const ScreenRecordState(status: ScreenRecordStatus.idle);
  }

  ScreenRecordState copyWith({ScreenRecordStatus? status, String? message}) {
    return ScreenRecordState(status: status ?? this.status, message: message);
  }
}
