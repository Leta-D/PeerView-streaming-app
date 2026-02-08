import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:peer_view/app_route/app_routes.dart';
import 'package:peer_view/constants/app_colors.dart';
import 'package:peer_view/logic/role_based_page_control/role__based_page_controller_cubit.dart';
import 'package:peer_view/logic/role_based_page_control/selected_role_state.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: BlocBuilder<RoleBasedPageController, UserRoleState>(
            builder: (context, state) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 25,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        context.read<RoleBasedPageController>().selectHost();
                      });
                    },
                    splashColor: Colors.white,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: state.role == UserRole.host
                            ? AppColors.neonColor(0.5)
                            : AppColors.neonColor(1),
                      ),
                      child: Text("Host"),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        context.read<RoleBasedPageController>().selectClient();
                      });
                    },
                    splashColor: Colors.white,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: state.role == UserRole.client
                            ? AppColors.red(0.5)
                            : AppColors.red(1),
                      ),
                      child: Text("Client"),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        state.role == UserRole.host
                            ? AppRoutes.hostMainPage
                            : AppRoutes.clientMainPage,
                        arguments: {
                          "animation": AppRouteAnimationType.fade,
                          "duration": 500,
                        },
                      );
                    },
                    child: Text("Next"),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
