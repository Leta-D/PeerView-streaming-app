import 'package:flutter/material.dart';

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
            IconButton(onPressed: () {}, icon: Icon(Icons.webhook_outlined)),
          ],
        ),
        SliverToBoxAdapter(
          child: ElevatedButton(onPressed: () {}, child: Text("Scan")),
        ),
      ],
    );
  }
}
