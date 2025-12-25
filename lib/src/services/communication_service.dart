// lib/src/services/communication_service.dart

import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

// Import your Agora App ID configuration
import '../../env/agora.dart';

class CommunicationService with ChangeNotifier {
  RtcEngine? _engine;
  int? _remoteUid;
  bool _localUserJoined = false;
  String? _currentChannel;

  // --- Public Getters ---
  RtcEngine? get engine => _engine;
  int? get remoteUid => _remoteUid;
  bool get localUserJoined => _localUserJoined;
  String? get currentChannel => _currentChannel;

  // ----------------------------------------------------
  // 1. ENGINE INITIALIZATION AND SETUP
  // ----------------------------------------------------

  Future<void> _handleCameraAndMicPermissions() async {
    // Check and request permissions
    await [Permission.camera, Permission.microphone].request();
  }

  /// Initializes the Agora RTC Engine and sets up event handlers.
  Future<void> initAgora() async {
    await _handleCameraAndMicPermissions();

    // 1. Check for App ID (Ensuring only the App ID is checked here)
    if (AgoraConfig.agoraAppId.isEmpty || AgoraConfig.agoraAppId.contains('YOUR_APP_ID_PLACEHOLDER')) {
      debugPrint('🛑 ERROR: Agora App ID is missing or placeholder. Cannot initialize engine.');
      return;
    }

    // 2. Create the Engine Instance (This is the critical step)
    try {
      _engine = createAgoraRtcEngine();

      await _engine!.initialize(RtcEngineContext(
        appId: AgoraConfig.agoraAppId,
      ));

      // 3. Enable Video and Set Role
      await _engine!.enableVideo();
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      // 4. Set up Event Handlers
      _addAgoraEventHandlers();

      debugPrint('CommunicationService: Agora Engine successfully initialized.');
    } catch (e) {
      debugPrint('🛑 ERROR during Agora Engine setup: $e');
      _engine = null;
      rethrow;
    }
  }

  // ----------------------------------------------------
  // 2. AGORA EVENT HANDLERS
  // ----------------------------------------------------

  void _addAgoraEventHandlers() {
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            debugPrint('CommunicationService: local user ${connection.localUid} joined successfully!');
            _localUserJoined = true;
            _currentChannel = connection.channelId;
            notifyListeners();
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            debugPrint('CommunicationService: remote user $remoteUid joined');
            _remoteUid = remoteUid;
            notifyListeners();
          },
          onUserOffline: (connection, remoteUid, reason) {
            debugPrint('CommunicationService: remote user $remoteUid left');
            _remoteUid = null;
            notifyListeners();
          },
          onLeaveChannel: (connection, stats) {
            debugPrint('CommunicationService: local user left channel');
            _localUserJoined = false;
            _remoteUid = null;
            _currentChannel = null;
            notifyListeners();
          },
          // This error handler is crucial for seeing authentication failure (token/channel errors)
          onError: (err, msg) {
            debugPrint('🛑 CommunicationService: Agora Error: $err, Message: $msg');
          }
      ),
    );
  }

  // ----------------------------------------------------
  // 3. CORE AGORA CONTROL METHODS
  // ----------------------------------------------------

  /// Joins the specified channel using the temporary token.
  Future<void> joinCall({
    required String channelName,
    required int userUid,
  }) async {
    if (_engine == null) {
      debugPrint('🛑 ERROR: Agora engine is null. Cannot join call.');
      return;
    }

    // Use token from the environment config
    final String? token = AgoraConfig.temporaryToken;

    if (token == null || token.isEmpty || token.contains('YOUR_AGORA_TEMP_TOKEN_HERE')) {
      debugPrint('🛑 WARNING: Agora token is missing or placeholder. Join will likely fail.');
      // Keep going, but warn the developer
    }

    await _engine!.joinChannel(
      token: token ?? '', // Use the actual token (or empty string if null)
      channelId: channelName, // Use the dynamically passed channel name
      uid: userUid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
    debugPrint("CommunicationService: Attempting to join channel: $channelName with UID: $userUid");
  }

  /// Ends the current call and releases resources.
  Future<void> endCall() async {
    if (_engine == null) return;
    try {
      await _engine!.leaveChannel();
      await _engine!.disableVideo();
    } catch (e) {
      debugPrint('Error leaving channel: $e');
    }
    _localUserJoined = false;
    _remoteUid = null;
    _currentChannel = null;
    notifyListeners();
  }

  /// Toggles the microphone on/off.
  Future<void> toggleMute(bool muted) async {
    if (_engine == null) return;
    // Removed the redundant await as per your previous implementation structure
    await _engine!.muteLocalAudioStream(muted);
  }

  /// Switches between front and back camera.
  Future<void> switchCamera() async {
    if (_engine == null) return;
    await _engine!.switchCamera();
  }

  // ----------------------------------------------------
  // 4. DISPOSE
  // ----------------------------------------------------

  @override
  void dispose() {
    // Release the engine resources on disposal
    _engine?.release();
    _engine = null;
    super.dispose();
  }
}