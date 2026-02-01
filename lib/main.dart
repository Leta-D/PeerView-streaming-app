import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:peer_view/app_route/app_route_generator.dart';
import 'package:peer_view/app_route/app_routes.dart';
import 'package:peer_view/logic/connection_handler/connection_handler_cubit.dart';
import 'package:peer_view/logic/permission_handler/permission_handler_cubit.dart';
import 'package:peer_view/logic/role_based_page_control/role__based_page_controller_cubit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => RoleBasedPageController()),
        BlocProvider(create: (_) => PermissionHandlerCubit()),
        BlocProvider(create: (_) => ConnectionHandlerCubit()),
      ],
      child: MaterialApp(
        title: 'Peer View',
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.roleSelection,
        onGenerateRoute: (settings) =>
            AppRoutesGenerator.generateRoute(settings),
      ),
    );
  }
}
