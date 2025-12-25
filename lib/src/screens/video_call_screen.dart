// lib/src/screens/video_call_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../services/communication_service.dart';
import '../services/patient_data_service.dart';
import '../providers/user_provider.dart';
import '../services/firebase_call_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final bool isHost;

  const VideoCallScreen({
    super.key,
    required this.channelName,
    required this.isHost,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool isMuted = false;
  // Note: isVideoDisabled state management is missing the actual Agora toggle logic

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCall();
    });
  }

  void _initializeCall() async {
    // Access providers using listen: false since we are in initState's callback
    final commService = Provider.of<CommunicationService>(context, listen: false);
    final patientService = Provider.of<PatientDataService>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Get the user's custom ID and generate a unique integer UID
    final String userIdString = userProvider.userCustomId ?? 'unknown_user';
    final int userUid = userIdString.hashCode;

    debugPrint('Joining channel: ${widget.channelName} with UID: $userUid');

    // 1. Join the Agora Channel
    // We assume the engine is already initialized in main.dart
    await commService.joinCall(
      channelName: widget.channelName,
      userUid: userUid,
    );

    // 2. Update Firebase Signaling Status (Legacy/Tracking)
    // NOTE: This should ideally be moved to a single CallStatus service.
    if (!widget.isHost) {
      patientService.setCallStatus('Patient Calling Staff');
    } else {
      patientService.setCallStatus('In Call');
    }
  }

  void _onCallEnd(BuildContext context) async {
    // Access providers using listen: false
    final commService = Provider.of<CommunicationService>(context, listen: false);
    final firebaseCallService = Provider.of<FirebaseCallService>(context, listen: false);
    final patientService = Provider.of<PatientDataService>(context, listen: false);

    // 1. Clear the Firebase RTDB Signaling Node
    await firebaseCallService.declineCall(); // Clears the /calls node

    // 2. Reset the legacy PatientDataService status
    await patientService.setCallStatus('Idle');

    // 3. End the Agora Call and release resources
    await commService.endCall();

    // 4. Navigate back
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Watch CommunicationService for real-time updates (especially remoteUid and engine status)
    final commService = context.watch<CommunicationService>();

    // Safety check for engine initialization
    if (commService.engine == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Video Call Error')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(30.0),
            child: Text(
              '🔴 FATAL ERROR: Video Engine not initialized. Please check CommunicationService setup.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red, fontSize: 18),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isHost ? 'Staff Call: ${widget.channelName}' : 'Patient Call',
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
  // VIDEO RENDERERS
  // -------------------------

  // Renders the remote user's video feed
  Widget _remoteVideo(CommunicationService commService) {
    // 🛑 CRITICAL CHECK: Ensure remoteUid is set by the CommunicationService's onUserJoined handler
    if (commService.remoteUid != null && commService.engine != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: commService.engine!,
          canvas: VideoCanvas(uid: commService.remoteUid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'Waiting for Robot/Patient video...',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }
  }

  // Renders the local user's video feed
  Widget _localVideo(CommunicationService commService) {
    // Check if the engine is ready AND the local user has successfully joined.
    if (commService.engine == null || !commService.localUserJoined) {
      return Container(
        color: Colors.grey[800],
        child: const Center(
          child: Icon(Icons.videocam_off, color: Colors.white, size: 40),
        ),
      );
    }

    // Render the local video (using UID 0 is standard for the local stream)
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: commService.engine!,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }

  // -------------------------
  // TOOLBAR CONTROLS
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
            // Mute Button
            RawMaterialButton(
              onPressed: () {
                setState(() {
                  isMuted = !isMuted;
                });
                if (commService.engine != null) commService.toggleMute(isMuted);
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
              onPressed: () {
                if (commService.engine != null) commService.switchCamera();
              },
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