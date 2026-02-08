import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:peer_view/app_route/app_routes.dart';
import 'package:peer_view/constants/app_colors.dart';
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
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.red(1),
            title: Text("Client"),
            expandedHeight: 170,
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.qrScanner);
                },
                icon: Icon(Icons.webhook_outlined),
              ),
            ],
          ),
          SliverToBoxAdapter(child: SizedBox(height: 25)),
          SliverToBoxAdapter(
            child: BlocBuilder<ConnectionHandlerCubit, ConnectionHandlerState>(
              builder: (context, state) {
                if (state is ConnectionHandlerInitialState) {
                  context.read<ConnectionHandlerCubit>().checkConnection();
                  return CircularProgressIndicator();
                } else if (state is ConnectionHandlerLoadingState) {
                  return CircularProgressIndicator();
                } else if (state is ConnectionHandlerLoadedState) {
                  return state.isConected
                      ? Column(children: [Text("connected")])
                      : Column(children: [Text("Not connected")]);
                }
                return ElevatedButton(onPressed: () {}, child: Text("Scan"));
              },
            ),
          ),
        ],
      ),
    );
  }
}
