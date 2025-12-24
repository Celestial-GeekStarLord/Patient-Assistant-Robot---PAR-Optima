// lib/src/services/communication_service.dart

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http; // 🛑 NEW IMPORT for network requests
import 'dart:convert'; // To decode JSON responses

// 🛑 IMPORTANT: Use your actual Agora App ID
const String agoraAppId = "YOUR_AGORA_APP_ID";

// 🛑 IMPORTANT: Replace this with the URL of your deployed Token Server
// Example: 'https://your-domain.com/agora/token'
const String tokenServerUrl = "http://127.0.0.1:8080/rtc/room_402/publisher/0";

class CommunicationService extends ChangeNotifier {
  RtcEngine? _engine;
  int? _remoteUid;
  bool _localUserJoined = false;

  // ... (Getters remain the same) ...
  RtcEngine? get engine => _engine;
  int? get remoteUid => _remoteUid;
  bool get localUserJoined => _localUserJoined;

  // ... (initAgora and _handlePermissions remain the same) ...

  // Initializes the Agora RTC Engine and sets up event handlers.
  Future<void> initAgora() async {
    // 1. Request Permissions
    await _handlePermissions();

    // 2. Create the engine
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(
      const RtcEngineContext(
        appId: agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    // 3. Set up event handlers
    _setupEngineEventHandlers();

    // 4. Enable necessary features
    await _engine!.enableVideo();
    await _engine!.setClientRole(ClientRoleType.clientRoleBroadcaster);

    notifyListeners();
  }

  Future<void> _handlePermissions() async {
    await [Permission.microphone, Permission.camera].request();
  }

  void _setupEngineEventHandlers() {
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("Local user joined: ${connection.localUid}");
          _localUserJoined = true;
          notifyListeners();
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("Remote user joined: $remoteUid");
          _remoteUid = remoteUid;
          notifyListeners();
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              debugPrint("Remote user left: $remoteUid");
              _remoteUid = null;
              notifyListeners();
            },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          debugPrint("Local user left channel");
          _localUserJoined = false;
          _remoteUid = null;
          notifyListeners();
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint("Agora Error: $err, $msg");
        },
      ),
    );
  }

  // -------------------------
  // SECURE TOKEN FETCHING
  // -------------------------

  /// 🛑 Fetches the secure RTC token from your deployed backend server.
  Future<String?> _fetchAgoraToken(String channelName, int uid) async {
    // 1. Construct the secure URL endpoint
    // Assuming your server endpoint takes the channel name and a user role/UID
    final String url = '$tokenServerUrl/$channelName/publisher/$uid';

    debugPrint("Fetching token from: $url");

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Example server response structure: {"rtcToken": "006...","uid": 0}
        final data = json.decode(response.body);
        final String token = data['rtcToken'];
        return token;
      } else {
        debugPrint(
          'Failed to load Agora token. Status code: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Network error fetching token: $e');
      return null;
    }
  }

  // -------------------------
  // CALL ACTIONS
  // -------------------------

  /// Joins the call channel securely after fetching a token.
  Future<void> joinCall(String channelName) async {
    // 🛑 1. Fetch the secure token dynamically
    // Using UID 0 lets Agora assign a random UID, simplifying the token server logic.
    const int uid = 0;
    final String? token = await _fetchAgoraToken(channelName, uid);

    if (token == null) {
      debugPrint("🛑 Error: Cannot join channel without a valid token.");
      return;
    }

    // 2. Join the channel with the secure token
    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(),
    );
  }

  /// Ends the call and disposes the engine.
  Future<void> endCall() async {
    try {
      await _engine?.leaveChannel();
      await _engine?.release();
      _engine = null;
      _localUserJoined = false;
      _remoteUid = null;
    } catch (e) {
      debugPrint("Error ending call: $e");
    } finally {
      notifyListeners();
    }
  }

  // ... (toggleMute, toggleVideo, switchCamera, dispose remain the same) ...
  Future<void> toggleMute(bool isMuted) async {
    await _engine?.muteLocalAudioStream(isMuted);
  }

  Future<void> toggleVideo(bool isDisabled) async {
    await _engine?.muteLocalVideoStream(isDisabled);
  }

  Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }

  @override
  void dispose() {
    endCall();
    super.dispose();
  }
}
