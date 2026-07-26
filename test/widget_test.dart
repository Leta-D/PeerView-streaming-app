import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peer_view_2/presentation/main_screens/role_selection_screen.dart';
import 'package:peer_view_2/core/di/injection.dart';

void main() {
  setUp(configureDependencies);

  testWidgets('Role selection screen shows host and client options', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RoleSelectionScreen()));

    expect(find.text('Host'), findsOneWidget);
    expect(find.text('Client'), findsOneWidget);
    expect(find.text('Choose a role'), findsOneWidget);
  });
}
