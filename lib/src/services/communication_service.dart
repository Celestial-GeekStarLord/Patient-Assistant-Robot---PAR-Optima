import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_functions/cloud_functions.dart';

// Import your Agora App ID configuration
import '../../env/agora.dart';

/// The CommunicationService manages all Agora Real-Time Communication (RTC)
/// functionalities, including engine initialization, token fetching via
/// Firebase Cloud Functions, joining/leaving channels, and handling callbacks.
class CommunicationService extends ChangeNotifier {
  RtcEngine? _engine;
  int? _remoteUid;
  bool _localUserJoined = false;

  // Public Getters for UI access
  RtcEngine? get engine => _engine;
  int? get remoteUid => _remoteUid;
  bool get localUserJoined => _localUserJoined;

  // ----------------------------------------------------
  // 1. ENGINE INITIALIZATION AND SETUP
  // ----------------------------------------------------

  /// Initializes the Agora RTC Engine and sets up event handlers.
  Future<void> initAgora() async {
    // 1. Request permissions (Crucial for Android/iOS)
    await _handleCameraAndMicPermissions();

    // 2. Create the engine instance
    _engine = createAgoraRtcEngine();

    // 3. Initialize the engine with the App ID from your secure config
    await _engine!.initialize(
      const RtcEngineContext(
        appId: AgoraConfig.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    // 4. Enable video and set up necessary config
    await _engine!.enableVideo();
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.startPreview();

    // 5. Set up event handlers
    _addAgoraEventHandlers();
  }

  // ----------------------------------------------------
  // 2. PERMISSIONS
  // ----------------------------------------------------

  /// Requests necessary camera and microphone permissions.
  Future<void> _handleCameraAndMicPermissions() async {
    // Note: Permission handling logic here is simplified.
    // Use a package like permission_handler for production apps.
  }

  // ----------------------------------------------------
  // 3. AGORA EVENT HANDLERS
  // ----------------------------------------------------

  /// Configures the callback methods for Agora events.
  void _addAgoraEventHandlers() {
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        // Local user successfully joined the channel
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint(
            "Local user ${connection.localUid} joined channel ${connection.channelId}",
          );
          _localUserJoined = true;
          notifyListeners();
        },

        // Remote user joined the channel
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint(
            "Remote user $remoteUid joined channel ${connection.channelId}",
          );
          _remoteUid = remoteUid;
          notifyListeners();
        },

        // Remote user left the channel
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              debugPrint(
                "Remote user $remoteUid left channel ${connection.channelId}",
              );
              _remoteUid = null;
              notifyListeners();
            },

        // Token is about to expire (Crucial for token renewal)
        onTokenPrivilegeWillExpire:
            (RtcConnection connection, String oldToken) async {
              debugPrint('Token will expire soon. Renewing...');

              // We reuse the local UID from the connection object for renewal
              final uid = connection.localUid ?? 0;

              // 1. Fetch the new token securely
              final newToken = await _fetchAgoraToken(
                connection.channelId ?? 'default_channel',
                uid,
              );

              if (newToken != null) {
                // 🛑 FIX: Call renewToken with the new token as a POSITIONAL ARGUMENT.
                await _engine!.renewToken(newToken);
                debugPrint('Token renewed successfully.');
              } else {
                debugPrint('Failed to renew token!');
              }
            },

        // Log any errors
        onError: (ErrorCodeType code, String message) {
          debugPrint('Agora Error: $code, Message: $message');
        },
      ),
    );
  }

  // ----------------------------------------------------
  // 4. SECURE TOKEN FETCHING (VIA FIREBASE FUNCTIONS)
  // ----------------------------------------------------

  /// Fetches the secure RTC token from the deployed Firebase Cloud Function.
  /// This replaces a direct HTTP call for increased security.
  Future<String?> _fetchAgoraToken(String channelName, int uid) async {
    const functionName =
        AgoraConfig.agoraTokenFunctionName; // Defined in agora.dart

    try {
      // 1. Call the Firebase Cloud Function
      final result = await FirebaseFunctions.instance
          .httpsCallable(functionName)
          .call({'channelName': channelName, 'uid': uid});

      // 2. Parse the result structure: { token: "..." }
      final String? token = result.data['token'];

      if (token == null) {
        debugPrint('Failed to fetch Agora token: Token field missing.');
        return null;
      }
      return token;
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'Firebase Function Error ($functionName): ${e.code} - ${e.message}',
      );
      // Log full error for debugging
      debugPrint('Firebase Function Details: ${e.details}');
      return null;
    } catch (e) {
      debugPrint('Unknown error calling Firebase Function: $e');
      return null;
    }
  }

  // ----------------------------------------------------
  // 5. CALL CONTROL METHODS
  // ----------------------------------------------------

  /// Joins the specified channel after fetching a secure token.
  Future<void> joinCall(String channelName) async {
    // Use UID 0 to let Agora assign a random UID
    const int uid = 0;

    // 1. Fetch Token
    final String? token = await _fetchAgoraToken(channelName, uid);

    if (token == null) {
      debugPrint("🛑 Error: Cannot join channel without a valid token.");
      return;
    }

    // 2. Join Channel
    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(),
    );
  }

  /// Ends the current call and releases resources.
  Future<void> endCall() async {
    await _engine?.leaveChannel();
    _remoteUid = null;
    _localUserJoined = false;
    // Destroy the engine instance to free native resources
    await _engine?.release();
    _engine = null;
    notifyListeners();
  }

  /// Toggles the microphone on/off.
  Future<void> toggleMute(bool muted) async {
    await _engine?.muteLocalAudioStream(muted);
    // You might want to notify listeners here if you display the mute status
  }

  /// Switches between front and back camera.
  Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }

  // ----------------------------------------------------
  // 6. DISPOSE
  // ----------------------------------------------------

  @override
  void dispose() {
    // Ensure the engine is released when the service is no longer needed
    endCall();
    super.dispose();
  }
}
