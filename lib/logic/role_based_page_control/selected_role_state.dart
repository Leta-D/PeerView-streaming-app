enum UserRole { none, host, client }

class UserRoleState {
  final UserRole role;
  final int currentIndex;
  final List<Map<String, dynamic>> pages;

  UserRoleState({
    required this.role,
    required this.currentIndex,
    required this.pages,
  });

  UserRoleState copyWith({
    UserRole? role,
    int? currentIndex,
    List<Map<String, dynamic>>? pages,
  }) {
    return UserRoleState(
      role: role ?? this.role,
      currentIndex: currentIndex ?? this.currentIndex,
      pages: pages ?? this.pages,
    );
  }
}
