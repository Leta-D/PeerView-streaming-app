// import 'package:flutter/material.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';

// class LocalScreenPreview extends StatelessWidget {
//   const LocalScreenPreview({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           Container(color: Colors.black), // main screen

//           Positioned(
//             bottom: 20,
//             right: 20,
//             width: 150,
//             height: 200,
//             child: Container(
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.white),
//               ),
//               child: FutureBuilder(
//                 future: showScreen(),
//                 builder: (context, snapshot) {
//                   if (snapshot.hasData) {
//                     // RTCVideoRenderer localPreview = snapshot.data
//                     return RTCVideoView(snapshot.data!);
//                   } else {
//                     return CircularProgressIndicator();
//                   }
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
