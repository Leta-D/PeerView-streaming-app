import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:peer_view/app_route/app_routes.dart';
import 'package:peer_view/logic/role_based_page_control/role__based_page_controller_cubit.dart';

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
                context.read<RoleBasedPageController>().selectHost();
              },
              child: Container(
                decoration: BoxDecoration(color: Colors.red),
                child: Text("Host"),
              ),
            ),
            InkWell(
              onTap: () {
                context.read<RoleBasedPageController>().selectClient();
              },
              child: Container(
                decoration: BoxDecoration(color: Colors.red),
                child: Text("Client"),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.roleSelection,
                  arguments: {
                    "animation": AppRouteAnimationType.fade,
                    "duration": 500,
                  },
                );
              },
              child: Text("Next"),
            ),
          ],
        ),
      ),
    );
  }
}
