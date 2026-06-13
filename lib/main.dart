import 'package:flutter/material.dart';
import 'package:peer_view_2/constants/app_theme.dart';
import 'package:peer_view_2/core/di/injection.dart';
import 'package:peer_view_2/presentation/main_screens/role_selection_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const PeerViewApp());
}

class PeerViewApp extends StatelessWidget {
  const PeerViewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peer View 2',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const RoleSelectionScreen(),
    );
  }
}
