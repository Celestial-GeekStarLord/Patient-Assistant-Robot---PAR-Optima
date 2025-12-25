// lib/src/services/communication_service.dart

import 'package:flutter/foundation.dart';
// Note: We need to import the entire package with a prefix to access types correctly
import 'package:agora_rtc_engine/agora_rtc_engine.dart' as agora;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:permission_handler/permission_handler.dart';

// --- SERVICE/PROVIDER IMPORTS ---
import '../providers/user_provider.dart';
import '../../env/agora.dart';

/// The CommunicationService manages all Agora Real-Time Communication (RTC)
/// functionalities, including engine initialization, token fetching via
/// Firebase Cloud Functions, joining/leaving channels, and handling callbacks.
class CommunicationService extends ChangeNotifier {
  agora.RtcEngine? _engine;
  int? _remoteUid;
  bool _localUserJoined = false;

  // Track states required by VideoCallScreen
  bool _isMuted = false;
  bool _isVideoDisabled = false;

  // Public Getters for UI access
  agora.RtcEngine? get engine => _engine;
  int? get remoteUid => _remoteUid;
  bool get localUserJoined => _localUserJoined;
  bool get isMuted => _isMuted;
  bool get isVideoDisabled => _isVideoDisabled;


  // ----------------------------------------------------
  // 1. ENGINE INITIALIZATION AND SETUP
  // ----------------------------------------------------

  /// Initializes the Agora RTC Engine and sets up event handlers.
  Future<void> initAgora() async {
    final bool permissionsGranted = await _handleCameraAndMicPermissions();

    if (!permissionsGranted) {
      debugPrint("⚠️ WARNING: Permissions not fully granted. Continuing init for testing...");
    }

    _engine = agora.createAgoraRtcEngine();

    await _engine!.initialize(
      const agora.RtcEngineContext(
        appId: AgoraConfig.agoraAppId,
        channelProfile: agora.ChannelProfileType.channelProfileCommunication,
      ),
    );

    await _engine!.enableVideo();
    await _engine!.setClientRole(role: agora.ClientRoleType.clientRoleBroadcaster);
    await _engine!.startPreview();

    _addAgoraEventHandlers();
  }

  // ----------------------------------------------------
  // 2. PERMISSIONS (IMPLEMENTATION)
  // ----------------------------------------------------

  Future<bool> _handleCameraAndMicPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();

    final granted = cameraStatus.isGranted && microphoneStatus.isGranted;

    if (!granted) {
      debugPrint("⚠️ Permissions not granted: Camera=${cameraStatus.isGranted}, Mic=${microphoneStatus.isGranted}");
    }
    return granted;
  }

  // ----------------------------------------------------
  // 3. AGORA EVENT HANDLERS
  // ----------------------------------------------------

  void _addAgoraEventHandlers() {
    _engine?.registerEventHandler(
      agora.RtcEngineEventHandler(
        onJoinChannelSuccess: (agora.RtcConnection connection, int elapsed) {
          debugPrint('✅ Local user joined channel: ${connection.localUid}');
          _localUserJoined = true;
          notifyListeners();
        },
        onUserJoined: (agora.RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint('🤝 Remote user joined: $remoteUid');
          _remoteUid = remoteUid;
          notifyListeners();
        },
        onUserOffline: (agora.RtcConnection connection, int remoteUid, agora.UserOfflineReasonType reason) {
          debugPrint('💔 Remote user offline: $remoteUid');
          _remoteUid = null;
          notifyListeners();
        },
        onLeaveChannel: (agora.RtcConnection connection, agora.RtcStats stats) {
          debugPrint('👋 Local user left channel.');
          _localUserJoined = false;
          _remoteUid = null;
          _isMuted = false;
          _isVideoDisabled = false;
          notifyListeners();
        },
        // 🛑 CRITICAL FINAL FIX: Removed explicit type annotations (LocalVideoState, LocalVideoError)
        // from the signature to force type inference and bypass the DDC compilation error.
        onLocalVideoStateChanged: (source, state, error) {
          // The enum values inside the body remain fully qualified with 'agora.'
          if (state == agora.LocalVideoState.localVideoStateCapturing) {
            debugPrint("📹 Local Video State: Capturing");
          } else if (state == agora.LocalVideoState.localVideoStateStopped) {
            debugPrint("📹 Local Video State: Stopped/Disabled");
          }
        },
      ),
    );
  }

  // ----------------------------------------------------
  // 4. CHANNEL MANAGEMENT
  // ----------------------------------------------------

  Future<String?> _fetchToken({
    required String channelName,
    required String uid,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('generateAgoraToken');
      final result = await callable.call(<String, dynamic>{
        'channelName': channelName,
        'uid': uid,
      });
      return result.data['token'];
    } catch (e) {
      debugPrint('🚨 ERROR fetching token: $e');
      return null;
    }
  }

  Future<void> joinCall(String channelName, String uid, String callerId) async {
    await joinChannel(channelName: channelName, uid: uid, callerId: callerId);
  }

  Future<void> joinChannel({
    required String channelName,
    required String uid,
    required String callerId, // Used for logging/token
  }) async {
    final token = await _fetchToken(channelName: channelName, uid: uid);

    if (token == null) {
      debugPrint("❌ Failed to join channel: Token is null.");
      return;
    }

    await _engine?.setClientRole(role: agora.ClientRoleType.clientRoleBroadcaster);

    // The `clientRole` parameter was removed from ChannelMediaOptions.
    await _engine?.joinChannel(
      token: token,
      channelId: channelName,
      uid: int.tryParse(uid) ?? 0,
      options: const agora.ChannelMediaOptions(
        channelProfile: agora.ChannelProfileType.channelProfileCommunication,
      ),
    );
  }

  Future<void> endCall() async {
    await leaveChannel();
  }

  Future<void> leaveChannel() async {
    await _engine?.leaveChannel();
    await _engine?.stopPreview();
    _localUserJoined = false;
    _remoteUid = null;
    _isMuted = false;
    _isVideoDisabled = false;
    notifyListeners();
  }

  Future<void> disposeEngine() async {
    await _engine?.release();
    _engine = null;
  }

  // ----------------------------------------------------
  // 5. VIDEO CALL CONTROL METHODS
  // ----------------------------------------------------

  Future<void> toggleMute(bool isMuted) async {
    _isMuted = isMuted;
    await _engine?.muteLocalAudioStream(_isMuted);
    notifyListeners();
  }

  Future<void> toggleVideo(bool isVideoDisabled) async {
    _isVideoDisabled = isVideoDisabled;
    await _engine?.enableLocalVideo(!_isVideoDisabled);
    notifyListeners();
  }

  Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }
}