import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:peer_view/logic/selected_role/selected_role_cubit.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          spacing: 25,
          children: [
            InkWell(
              onTap: () {
                context.read<SelectedRoleCubit>().selectHost();
              },
              child: Container(
                decoration: BoxDecoration(color: Colors.red),
                child: Text("Host"),
              ),
            ),
            InkWell(
              onTap: () {
                context.read<SelectedRoleCubit>().selectClient();
              },
              child: Container(
                decoration: BoxDecoration(color: Colors.red),
                child: Text("Client"),
              ),
            ),
            ElevatedButton(onPressed: () {}, child: Text("Next")),
          ],
        ),
      ),
    );
  }
}
