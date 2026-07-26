import 'package:flutter/material.dart';
import 'package:peer_view_2/app/screens/role_selection_screen.dart';
import 'package:peer_view_2/core/di/injection.dart';

void main() {
  configureDependencies();
  runApp(const PeerViewApp());
}

class PeerViewApp extends StatelessWidget {
  const PeerViewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peer View 2',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const RoleSelectionScreen(),
    );
  }
}
