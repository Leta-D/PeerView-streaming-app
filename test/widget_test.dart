import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peer_view_2/constants/app_theme.dart';
import 'package:peer_view_2/core/di/injection.dart';
import 'package:peer_view_2/presentation/main_screens/role_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await configureDependencies();
  });

  testWidgets('Role selection screen shows host and client options', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const RoleSelectionScreen(),
      ),
    );

    expect(find.text('Host'), findsOneWidget);
    expect(find.text('Client'), findsOneWidget);
    expect(find.textContaining('Choose'), findsOneWidget);
  });
}
