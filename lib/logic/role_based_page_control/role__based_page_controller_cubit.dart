import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:peer_view/logic/role_based_page_control/selected_role_state.dart';

class RoleBasedPageController extends Cubit<UserRoleState> {
  final List<Map<String, dynamic>> hostPages = [
    // fill the pages in here as u create for host
  ];

  final List<Map<String, dynamic>> clientPages = [
    // fill the pages in here as u create for client
  ];

  RoleBasedPageController()
    : super(UserRoleState(role: UserRole.none, currentIndex: 0, pages: []));

  void selectHost() {
    emit(UserRoleState(role: UserRole.host, currentIndex: 0, pages: hostPages));
  }

  void selectClient() {
    emit(
      UserRoleState(role: UserRole.client, currentIndex: 0, pages: clientPages),
    );
  }

  void changeMainPageIndex(int index) {
    emit(state.copyWith(currentIndex: index));
  }
}
