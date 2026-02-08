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
      backgroundColor: AppColors.bgDark(1),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.bgDark(1),
            foregroundColor: AppColors.red(0.6),
            pinned: true,
            expandedHeight: 140,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'CLIENT',
                style: TextStyle(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white38,
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.qrScanner,
                    arguments: {
                      "animation": AppRouteAnimationType.fade,
                      "duration": 600,
                    },
                  ).then((value) {
                    context.read<ConnectionHandlerCubit>().checkConnection();
                  });
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
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.cardDark(1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.red(0.4)),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'NOT CONNECTIONED To HOST',
                                  style: TextStyle(
                                    color: AppColors.red(1),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(height: 27),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.red(1),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.qrScanner,
                                        arguments: {
                                          "animation":
                                              AppRouteAnimationType.fade,
                                          "duration": 600,
                                        },
                                      ).then((value) {
                                        context
                                            .read<ConnectionHandlerCubit>()
                                            .checkConnection();
                                      });
                                    },
                                    icon: Icon(
                                      Icons.qr_code_scanner_outlined,
                                      color: Colors.white,
                                      size: 23,
                                    ),
                                    label: const Text(
                                      'SCAN QR',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 25),
                              ],
                            ),
                          ),
                        );
                }
                return Text("Some Error");
              },
            ),
          ),
        ],
      ),
    );
  }
}
