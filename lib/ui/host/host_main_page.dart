import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:peer_view/app_route/app_routes.dart';
import 'package:peer_view/constants/app_colors.dart';
import 'package:peer_view/logic/screen_share/screen_share_bloc.dart';
import 'package:peer_view/logic/screen_share/screen_share_event.dart';
import 'package:peer_view/logic/screen_share/screen_share_state.dart';
import 'package:peer_view/test_screen.dart';

class HostMainPage extends StatefulWidget {
  const HostMainPage({super.key});

  @override
  State<HostMainPage> createState() => _HostMainPageState();
}

class _HostMainPageState extends State<HostMainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark(1),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.bgDark(1),
            foregroundColor: AppColors.neonColor(0.6),
            pinned: true,
            expandedHeight: 140,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'HOST ',
                style: TextStyle(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white38,
                ),
              ),
            ),
            // title: Text("Host"),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.qrGenerator,
                    arguments: {
                      "animation": AppRouteAnimationType.fade,
                      "duration": 600,
                    },
                  );
                },
                icon: Icon(Icons.qr_code_2_rounded),
              ),
            ],
          ),
          SliverToBoxAdapter(child: SizedBox(height: 30)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardDark(1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.neonColor(0.4)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Start Streaming Your Game Play',
                      style: TextStyle(
                        color: AppColors.neonColor(1),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 27),

                    BlocBuilder<ScreenShareBloc, ScreenShareState>(
                      builder: (context, state) {
                        if (state is ScreenShareLoading) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (state is ScreenShareStreaming) {
                          return Center(child: Text('Streaming started'));
                        }
                        if (state is ScreenShareError) {
                          print(state.message);
                          return Center(
                            child: Column(
                              children: [
                                Text(
                                  'Error: ${state.message}',
                                  style: TextStyle(color: AppColors.red(1)),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.neonColor(1),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: () {
                                      context.read<ScreenShareBloc>().add(
                                        StartScreenShare(),
                                      );
                                    },
                                    icon: Icon(
                                      Icons.stream_rounded,
                                      color: Colors.black,
                                      size: 23,
                                    ),
                                    label: const Text(
                                      'Retry',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return Center(
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.neonColor(1),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () {
                                context.read<ScreenShareBloc>().add(
                                  StartScreenShare(),
                                );
                              },
                              icon: Icon(
                                Icons.stream_rounded,
                                color: Colors.black,
                                size: 23,
                              ),
                              label: const Text(
                                'STREAM',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LocalScreenPreview(),
                          ),
                        );
                      },
                      child: const Text("Preview Local Stream"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
