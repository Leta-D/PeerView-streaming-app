import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peer_view/app_route/app_routes.dart';
import 'package:peer_view/constants/app_colors.dart';
import 'package:peer_view/logic/offer_logic/hosts/broadcast_cubit.dart';
import 'package:peer_view/logic/offer_logic/hosts/broadcast_state.dart';
import 'package:peer_view/logic/offer_logic/hosts/hh/host_stream_bloc.dart';
import 'package:peer_view/logic/offer_logic/hosts/hh/host_stream_event.dart';
import 'package:peer_view/logic/screen_recording/screen_record_cubit.dart';
import 'package:peer_view/logic/screen_recording/screen_record_service.dart';
import 'package:peer_view/logic/screen_recording/screen_record_state.dart';

class HostMainPage extends StatefulWidget {
  const HostMainPage({super.key});

  @override
  State<HostMainPage> createState() => _HostMainPageState();
}

class _HostMainPageState extends State<HostMainPage> {
  bool _showPreview = false;
  bool _fullScreenPreview = false;
  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: AppColors.bgDark(1),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.bgDark(1),
                foregroundColor: AppColors.neonColor(0.6),
                pinned: true,
                expandedHeight: 140,

                flexibleSpace: FlexibleSpaceBar(
                  title:
                      const Text(
                        'HOST ',
                        style: TextStyle(
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white38,
                        ),
                      ).animate(
                        effects: [
                          FadeEffect(duration: 600.ms, curve: Curves.easeInOut),
                          RotateEffect(
                            duration: 1200.ms,
                            curve: Curves.easeInOut,
                          ),
                        ],
                      ),
                ),
                leading: IconButton(
                  onPressed: () {
                    if (context.read<BroadcastCubit>().state
                        is BroadcastingState) {
                      context.read<BroadcastCubit>().stopBroadcast();
                    }
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back_ios_new),
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
                  child:
                      Container(
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

                            BlocConsumer<BroadcastCubit, BroadcastState>(
                              listener: (context, state) {
                                if (state is BroadcastingState) {
                                  context.read<HostBloc>().add(
                                    StartHostStreamEvent(),
                                  );
                                }
                              },
                              builder: (context, state) {
                                if (state is BroadcastingInitialState) {
                                  return Row(
                                    spacing: 20,
                                    children: [
                                      CircularProgressIndicator(
                                        strokeWidth: 1.3,
                                      ),
                                      Text(
                                        "Initiating broadcast...",
                                        style: TextStyle(
                                          color: AppColors.neonColor(1),
                                        ),
                                      ),
                                    ],
                                  );
                                }
                                return SizedBox.shrink();
                              },
                            ),

                            Center(
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
                                    context
                                        .read<ScreenRecordCubit>()
                                        .startRecording();
                                  },
                                  icon: Icon(
                                    Icons.stream_rounded,
                                    color: Colors.black,
                                    size: 23,
                                  ),
                                  label: const Text(
                                    'Broadcast',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 25),

                            BlocBuilder<BroadcastCubit, BroadcastState>(
                              builder: (context, state) {
                                if (state is BroadcastingErrorState) {
                                  return Text(
                                    "Error occured on broadcasting \n ${state.errorMessage}",
                                    style: TextStyle(
                                      color: AppColors.neonColor(1),
                                    ),
                                  );
                                }
                                if (state is BroadcastingState) {
                                  return Column(
                                    children: [
                                      Text(
                                        "Broadcasting ...",
                                        style: TextStyle(
                                          color: AppColors.neonColor(1),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          context
                                              .read<BroadcastCubit>()
                                              .stopBroadcast();
                                        },
                                        child: Text("Stop"),
                                      ),
                                    ],
                                  );
                                }
                                if (state is BroadcastingStoppedState) {
                                  return Text(
                                    "Broadcasting Stopped",
                                    style: TextStyle(
                                      color: AppColors.neonColor(1),
                                    ),
                                  );
                                }
                                return Text(
                                  "Tap to start broadcasting",
                                  style: TextStyle(
                                    color: AppColors.neonColor(1),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ).animate(
                        effects: [
                          FadeEffect(duration: 600.ms, curve: Curves.easeInOut),
                          FlipEffect(duration: 600.ms, curve: Curves.easeInOut),
                        ],
                      ),
                ),
              ),
            ],
          ),
          BlocConsumer<ScreenRecordCubit, ScreenRecordState>(
            listener: (context, state) {
              if (state is RecordingScreenRecordState) {
                context.read<BroadcastCubit>().startBroadcast();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Show Preview"),
                    action: SnackBarAction(
                      backgroundColor: AppColors.cardDark(1),
                      textColor: AppColors.neonColor(1),
                      label: "Show",
                      onPressed: () {
                        setState(() {
                          _showPreview = true;
                        });
                      },
                    ),
                    closeIconColor: AppColors.neonColor(1),
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is RecordingScreenRecordState) {
                return (_showPreview)
                    ? Positioned(
                        right: 10,
                        bottom: 10,
                        child: Column(
                          children: [
                            Row(
                              spacing: _fullScreenPreview
                                  ? screenSize.width - 150
                                  : 40,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _fullScreenPreview = !_fullScreenPreview;
                                    });
                                  },
                                  icon: Icon(
                                    _fullScreenPreview
                                        ? Icons.fullscreen_exit_rounded
                                        : Icons.close_fullscreen,
                                    color: AppColors.neonColor(0.8),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() async {
                                      await context
                                          .read<ScreenRecordCubit>()
                                          .stopRecording();
                                      _showPreview = false;
                                      _fullScreenPreview = false;
                                    });
                                  },
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: AppColors.red(0.8),
                                  ),
                                ),
                              ],
                            ),
                            AnimatedContainer(
                              duration: 500.ms,
                              curve: Curves.easeInOut,
                              width: _fullScreenPreview
                                  ? screenSize.width - 20
                                  : screenSize.width / 2.9,
                              height: _fullScreenPreview
                                  ? screenSize.height / 2
                                  : screenSize.height / 3.6,
                              child: FutureBuilder(
                                future: ScreenRecordService.showScreen(
                                  (BlocProvider.of<ScreenRecordCubit>(
                                            context,
                                          ).state
                                          as RecordingScreenRecordState)
                                      .screenMedia,
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.neonColor(0.5),
                                        ),
                                      ),
                                      child: RTCVideoView(snapshot.data!),
                                    );
                                  } else if (snapshot.hasError) {
                                    return Container(
                                      color: AppColors.red(1),
                                      child: Icon(
                                        Icons.error_outline,
                                        color: Colors.white,
                                      ),
                                    );
                                  } else {
                                    return CircularProgressIndicator();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ).animate(
                        effects: [
                          FadeEffect(duration: 500.ms, curve: Curves.easeInOut),
                        ],
                      )
                    : Positioned(
                        right: 20,
                        bottom: 20,
                        child: Container(
                          color: AppColors.red(1),
                          width: 20,
                          height: 21,
                        ),
                        // child: FloatingActionButton(
                        //   onPressed: () {
                        //     setState(() {
                        //       _showPreview = true;
                        //     });
                        //   },
                        //   backgroundColor: AppColors.cardDark(0.7),
                        //   tooltip: "Show Preview",
                        //   child: Icon(
                        //     Icons.preview_rounded,
                        //     color: AppColors.neonColor(1),
                        //   ),
                        // ),
                      );
              }
              if (state is ErrorScreenRecordState) {
                return Text(
                  "Error: ${state.errorMessage}",
                  style: TextStyle(color: AppColors.neonColor(1)),
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
