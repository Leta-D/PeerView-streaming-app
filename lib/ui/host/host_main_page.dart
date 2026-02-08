import 'package:flutter/material.dart';
import 'package:peer_view/app_route/app_routes.dart';
import 'package:peer_view/constants/app_colors.dart';

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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonColor(1),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {},
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
                    SizedBox(height: 25),
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
