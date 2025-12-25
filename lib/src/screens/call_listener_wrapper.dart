// // lib/src/screens/call_listener_wrapper.dart
//
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../services/call_service.dart';
// import 'video_call_screen.dart';
//
// class CallListenerWrapper extends StatelessWidget {
//   final Widget child; // The RobotInterface or PatientDashboard
//   final String localUserId;
//
//   const CallListenerWrapper({
//     super.key,
//     required this.child,
//     required this.localUserId,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     // 1. Get the CallService instance
//     final callService = Provider.of<CallService>(context);
//
//     // 2. Continuous Check: If a call is pending AND the token is available, navigate!
//     if (callService.currentCall != null && callService.agoraToken != null) {
//
//       // Use microtask to navigate outside of the build method
//       Future.microtask(() {
//         Navigator.of(context).push(
//           MaterialPageRoute(
//             builder: (context) => VideoCallScreen(
//               channelName: callService.currentCall!.channelId,
//               // The caller/robot is the host for this specific signaling flow
//               isHost: true,
//             ),
//           ),
//         ).then((_) {
//           // IMPORTANT: When the user returns from the call screen, clear the call state
//           callService.endCall();
//         });
//       });
//     }
//
//     // 3. Display the actual UI
//     return child;
//   }
// }