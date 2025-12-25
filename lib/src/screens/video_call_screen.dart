// lib/src/screens/video_call_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// 🛑 IMPORTANT: Use the prefixed import for Agora enums/classes
import 'package:agora_rtc_engine/agora_rtc_engine.dart' as agora;
import '../services/communication_service.dart';
import '../services/call_service.dart'; // 🛑 NEW: Use the dedicated CallService
import '../providers/user_provider.dart'; // 🛑 NEW: Required for fetching user ID/name

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final bool isHost; // True for Staff, false for Patient/Robot

  const VideoCallScreen({
    super.key,
    required this.channelName,
    required this.isHost,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  // State variables for UI controls
  bool isMuted = false;
  bool isVideoDisabled = false; // New state variable for video toggle

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  void _initializeCall() async {
    // We use listen: false since this is in initState
    final commService = Provider.of<CommunicationService>(
      context,
      listen: false,
    );
    final callService = Provider.of<CallService>(
      context,
      listen: false,
    );
    // 🛑 NEW: Fetch UserProvider to get IDs for joining the channel
    final userProvider = Provider.of<UserProvider>(
      context,
      listen: false,
    );

    // Get required IDs
    // 🛑 FIX: Removed the non-existent 'userProvider.userId' fallback.
    final String uid = userProvider.userCustomId ?? '0';
    final String callerName = userProvider.userName ?? 'User';

    // 🛑 CRITICAL FIX: Ensure the Agora Engine is initialized before joining the channel.
    if (commService.engine == null) {
      debugPrint("🛠️ Initializing Agora Engine from VideoCallScreen...");
      try {
        await commService.initAgora();
        debugPrint("✅ Agora Engine Initialized.");
      } catch (e) {
        debugPrint("🔴 ERROR: Failed to initialize Agora Engine: $e");
        return;
      }
    }

    // 1. Join the Agora Channel
    // 🛑 FIX: Pass all three required arguments (channelName, uid, callerName)
    await commService.joinCall(widget.channelName, uid, callerName);

    // 2. Update Firebase Signaling Status using the new CallService
    // Only update status if the call is currently ringing (i.e., this user is the receiver).
    if (callService.currentCall?.status == 'ringing') {
      await callService.acceptCall();
      debugPrint("✅ CallService: Status changed to 'accepted'.");
    }
  }

  void _onCallEnd(BuildContext context) async {
    // 1. Get Services
    final commService = Provider.of<CommunicationService>(
      context,
      listen: false,
    );
    final callService = Provider.of<CallService>(
      context,
      listen: false,
    );

    debugPrint("🛑 END CALL: Starting cleanup sequence...");

    try {
      // 2. End the Agora Call and release resources first.
      await commService.endCall();
      debugPrint("✅ Agora Engine released.");
    } catch (e) {
      debugPrint("⚠️ WARNING: Error during commService.endCall(): $e");
    }

    try {
      // 3. Reset Firebase Call Status using the CallService
      // This removes the call document from Firebase.
      await callService.endCall();
      debugPrint("✅ Firebase Call Document removed.");
    } catch (e) {
      debugPrint("⚠️ WARNING: Error during callService.endCall(): $e");
    }

    // 4. Navigate back ONLY IF the widget is still mounted.
    if (mounted) {
      Navigator.pop(context);
      debugPrint("✅ Navigation complete.");
    } else {
      debugPrint("❌ Widget not mounted. Navigation skipped.");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes in CommunicationService (remoteUid, localUserJoined)
    final commService = Provider.of<CommunicationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isHost ? 'Staff Call: ${widget.channelName}' : 'Robot Call',
        ),
        backgroundColor: Colors.indigo,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // 1. Main Video Window (Remote User)
          Center(child: _remoteVideo(commService)),

          // 2. Local Video Overlay (Mini-view)
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: 100,
              height: 150,
              margin: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _localVideo(commService),
              ),
            ),
          ),

          // 3. Control Panel (Bottom)
          _toolbar(context, commService),
        ],
      ),
    );
  }

  // -------------------------
  // VIDEO RENDERERS (Updated to use prefixed Agora classes)
  // -------------------------

  // Renders the remote user's video feed
  Widget _remoteVideo(CommunicationService commService) {
    // Show a fallback widget if the engine hasn't been initialized yet
    if (commService.engine == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text('Initializing...', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    if (commService.remoteUid != null) {
      // 🛑 FIX: Use prefixed Agora classes
      return agora.AgoraVideoView(
        controller: agora.VideoViewController.remote(
          rtcEngine: commService.engine!,
          canvas: const agora.VideoCanvas(), // uid is 0 for the local user in remote canvas
          connection: agora.RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'Waiting for the other party...',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }
  }

  // Renders the local user's video feed
  Widget _localVideo(CommunicationService commService) {
    // Show a fallback widget if the engine hasn't been initialized yet or user hasn't joined
    if (commService.engine == null || !commService.localUserJoined) {
      return Container(
        color: Colors.grey[800],
        child: const Center(
          child: Icon(Icons.videocam_off, color: Colors.white, size: 40),
        ),
      );
    }

    // If local video is explicitly disabled by the user
    if (isVideoDisabled) {
      return Container(
        color: Colors.grey[800],
        child: const Center(
          child: Icon(Icons.person, color: Colors.white, size: 40), // Placeholder icon
        ),
      );
    }

    // Use uid = 0 for the local stream
    // 🛑 FIX: Use prefixed Agora classes
    return agora.AgoraVideoView(
      controller: agora.VideoViewController(
        rtcEngine: commService.engine!,
        canvas: const agora.VideoCanvas(uid: 0),
      ),
    );
  }

  // -------------------------
  // TOOLBAR CONTROLS (UNCHANGED, relies on fixed service methods)
  // -------------------------
  Widget _toolbar(BuildContext context, CommunicationService commService) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        color: Colors.black45,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            // Mute Audio Button
            RawMaterialButton(
              onPressed: () {
                setState(() {
                  isMuted = !isMuted;
                  commService.toggleMute(isMuted);
                });
              },
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: isMuted ? Colors.blueGrey : Colors.white,
              padding: const EdgeInsets.all(12.0),
              child: Icon(
                isMuted ? Icons.mic_off : Icons.mic,
                color: isMuted ? Colors.white : Colors.blueGrey,
                size: 20.0,
              ),
            ),

            // Mute Video Button
            RawMaterialButton(
              onPressed: () {
                setState(() {
                  isVideoDisabled = !isVideoDisabled;
                  commService.toggleVideo(isVideoDisabled);
                });
              },
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: isVideoDisabled ? Colors.blueGrey : Colors.white,
              padding: const EdgeInsets.all(12.0),
              child: Icon(
                isVideoDisabled ? Icons.videocam_off : Icons.videocam,
                color: isVideoDisabled ? Colors.white : Colors.blueGrey,
                size: 20.0,
              ),
            ),

            // Hangup Button
            RawMaterialButton(
              onPressed: () => _onCallEnd(context),
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.redAccent,
              padding: const EdgeInsets.all(15.0),
              child: const Icon(
                Icons.call_end,
                color: Colors.white,
                size: 35.0,
              ),
            ),

            // Camera Switch Button
            RawMaterialButton(
              onPressed: () => commService.switchCamera(),
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.white,
              padding: const EdgeInsets.all(12.0),
              child: const Icon(
                Icons.switch_camera,
                color: Colors.blueGrey,
                size: 20.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}