import 'package:flutter/material.dart';
import 'package:peer_view/app_route/app_routes.dart';

class HostMainPage extends StatefulWidget {
  const HostMainPage({super.key});

  @override
  State<HostMainPage> createState() => _HostMainPageState();
}

class _HostMainPageState extends State<HostMainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text("Host"),
            expandedHeight: 150,
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.qrGenerator);
                },
                icon: Icon(Icons.qr_code_2_rounded),
              ),
            ],
          ),
          SliverToBoxAdapter(child: SizedBox(height: 30)),
          SliverToBoxAdapter(
            child: ElevatedButton(onPressed: () {}, child: Text("Stream")),
          ),
        ],
      ),
    );
  }
}
