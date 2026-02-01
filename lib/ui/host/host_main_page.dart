import 'package:flutter/material.dart';

class HostMainPage extends StatefulWidget {
  const HostMainPage({super.key});

  @override
  State<HostMainPage> createState() => _HostMainPageState();
}

class _HostMainPageState extends State<HostMainPage> {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: Text("Host"),
          expandedHeight: 150,
          actions: [
            IconButton(onPressed: () {}, icon: Icon(Icons.qr_code_2_rounded)),
          ],
        ),
        SliverToBoxAdapter(child: SizedBox(height: 30)),
        SliverToBoxAdapter(
          child: ElevatedButton(onPressed: () {}, child: Text("Stream")),
        ),
      ],
    );
  }
}
