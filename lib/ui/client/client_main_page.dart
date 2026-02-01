import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:peer_view/app_route/app_routes.dart';
import 'package:peer_view/logic/connection_handler/connection_handler_cubit.dart';
import 'package:peer_view/logic/connection_handler/connection_handler_state.dart';

class ClientMainPage extends StatefulWidget {
  const ClientMainPage({super.key});

  @override
  State<ClientMainPage> createState() => _ClientMainPageState();
}

class _ClientMainPageState extends State<ClientMainPage> {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: Text("Client"),
          expandedHeight: 200,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.qrScanner);
              },
              icon: Icon(Icons.webhook_outlined),
            ),
          ],
        ),
        BlocBuilder<ConnectionHandlerCubit, ConnectionHandlerState>(
          builder: (context, state) {
            if (state is ConnectionHandlerLoadingState) {
              return SliverToBoxAdapter(child: CircularProgressIndicator());
            } else if (state is ConnectionHandlerLoadingState) {
              return SliverToBoxAdapter(child: Text("Connected"));
            }
            return SliverToBoxAdapter(
              child: ElevatedButton(onPressed: () {}, child: Text("Scan")),
            );
          },
        ),
      ],
    );
  }
}
