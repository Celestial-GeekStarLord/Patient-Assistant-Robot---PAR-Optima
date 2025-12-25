// lib/src/screens/video_call_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart'; // 🛑 Correct import for video views
import '../services/communication_service.dart';
import '../services/patient_data_service.dart';

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
  bool isMuted = false;
  bool isVideoDisabled = false;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  void _initializeCall() async {
    final commService = Provider.of<CommunicationService>(
      context,
      listen: false,
    );
    final patientService = Provider.of<PatientDataService>(
      context,
      listen: false,
    );

    // 1. Join the Agora Channel
    await commService.joinCall(widget.channelName);

    // 2. Update Firebase Signaling Status
    // Note: The channelName in this example is static ("room_402"),
    // but in a multi-room app, you would pass a dynamic ID to setCallStatus
    if (!widget.isHost) {
      // If Patient or Robot initiates the call, set status to 'Calling'
      patientService.setCallStatus('Patient Calling Staff');
    } else {
      // If Staff initiated the call, they are just joining
      patientService.setCallStatus('In Call');
    }
  }

  void _onCallEnd(BuildContext context) async {
    final commService = Provider.of<CommunicationService>(
      context,
      listen: false,
    );
    final patientService = Provider.of<PatientDataService>(
      context,
      listen: false,
    );

    // 1. Reset Firebase Call Status
    await patientService.setCallStatus('Idle');

    // 2. End the Agora Call and release resources
    await commService.endCall();

    // 3. Navigate back
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final commService = Provider.of<CommunicationService>(context);

    //

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
    // Show a fallback widget if the engine hasn't been initialized yet
    if (commService.engine == null)
      return const Center(
        child: Text('Initializing...', style: TextStyle(color: Colors.white)),
      );

    if (commService.remoteUid != null) {
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
            'Waiting for the other party...',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }
  }

  // Renders the local user's video feed
  Widget _localVideo(CommunicationService commService) {
    // Show a fallback widget if the engine hasn't been initialized yet
    if (commService.engine == null || !commService.localUserJoined) {
      return Container(
        color: Colors.grey[800],
        child: const Center(
          child: Icon(Icons.videocam_off, color: Colors.white, size: 40),
        ),
      );
    }

    // Use uid = 0 for the local stream
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
                isMuted = !isMuted;
                commService.toggleMute(isMuted);
                setState(() {});
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
