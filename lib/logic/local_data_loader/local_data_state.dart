abstract class LocalDataState {}

class LocalDataInitialState extends LocalDataState {}

class LocalDataLoadingState extends LocalDataState {}

class LocalDataLoadedState extends LocalDataState {
  final String hostName;

  LocalDataLoadedState({required this.hostName});
}

class LocalDataErrorState extends LocalDataState {
  final String errorMessage;

  LocalDataErrorState({required this.errorMessage});
}
