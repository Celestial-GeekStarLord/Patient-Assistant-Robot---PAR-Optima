// lib/src/services/firebase_call_service.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';

// Imports for the interface and models
import 'call_service.dart';
import '../models/call_model.dart';
import '../providers/user_provider.dart';

// Imports for the Agora configuration
import '../../env/agora.dart';

/// This service handles all call signaling logic via Firebase Realtime Database (RTDB).
/// It implements the CallService interface.
class FirebaseCallService extends CallService {
  final DatabaseReference _callsRef = FirebaseDatabase.instance.ref('calls');
  DatabaseReference? _callListenerRef;

  // --- CallService Properties Implementation ---

  // We use the fixed token from the environment for this hackathon scenario
  @override
  String? get agoraToken => AgoraConfig.temporaryToken;

  // Internal state variables
  CallModel? _call;
  CallStatus _status = CallStatus.idle;

  @override
  CallModel? get currentCall => _call;

  @override
  CallStatus get status => _status;

  // The service is ready as soon as it's initialized
  @override
  bool get isReady => true;

  // --- Core Signaling Methods Implementation ---

  /// Initiates an outbound call by writing the call model to the receiver's RTDB node.
  @override
  Future<bool> makeCall({
    required UserProvider caller,
    required String receiverId,
    required String receiverName
  }) async {
    if (caller.userCustomId == null || caller.userName == null) return false;

    // Use the fixed channel name defined in your configuration
    const String channelName = AgoraConfig.testChannelName;

    final CallModel newCall = CallModel(
      callerId: caller.userCustomId!,
      callerName: caller.userName!,
      receiverId: receiverId,
      receiverName: receiverName,
      channelId: channelName,
      status: 'ringing', // The state that triggers the Staff UI
      isRobot: true,
    );

    _call = newCall;

    // Write the call data to the receiver's call node in RTDB (e.g., calls/staff_101)
    await _callsRef.child(receiverId).set(newCall.toMap());

    _status = CallStatus.ringing;
    notifyListeners();
    debugPrint('FirebaseCallService: Initiated signaling to $receiverName on channel $channelName');
    return true;
  }

  /// Called by the receiver (Staff) to accept an incoming call.
  @override
  Future<void> acceptCall() async {
    if (_call == null) return;

    // Update the status in RTDB
    await _callsRef.child(_call!.receiverId).update({'status': 'accepted'});

    // Update local state
    _call = _call!.copyWith(status: 'accepted');
    _status = CallStatus.connected;
    notifyListeners();
  }

  /// Ends the call (clears the RTDB node and resets local state).
  @override
  Future<void> declineCall() async {
    if (_call == null) return;

    final String receiverId = _call!.receiverId;
    final String callerId = _call!.callerId;

    // Clear the call from both parties' nodes (if they exist)
    await _callsRef.child(receiverId).remove();
    // This is optional/safer, only needed if the caller also listens to their own node
    await _callsRef.child(callerId).remove();

    _call = null;
    _status = CallStatus.idle;
    notifyListeners();
    debugPrint('FirebaseCallService: Signaling ended and cleared.');
  }

  // --- Listener Management Implementation ---

  /// Starts listening for incoming call signals for the local user ID.
  @override
  void startListeningForCalls(String localUserId) {
    if (localUserId.isEmpty) return;

    // Ensure previous listener is closed before starting a new one
    _callListenerRef?.onValue.drain();

    _callListenerRef = _callsRef.child(localUserId);

    _callListenerRef!.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        final CallModel call = CallModel.fromMap(Map<String, dynamic>.from(data));

        // Update local state based on RTDB data
        _call = call;

        // Map the string status from the RTDB model to the CallStatus enum
        switch (call.status) {
          case 'ringing':
            _status = CallStatus.ringing;
            break;
          case 'accepted':
            _status = CallStatus.connected;
            break;
          default:
            _status = CallStatus.idle;
        }

        notifyListeners();
        debugPrint('FirebaseCallService: INCOMING CALL state updated to: $status');

      } else {
        // Node was cleared (call ended by remote party)
        if (_call != null) {
          _call = null;
          _status = CallStatus.idle;
          notifyListeners();
          debugPrint('FirebaseCallService: Call ended by remote party.');
        }
      }
    });

    debugPrint('FirebaseCallService: Started RTDB listener on calls/$localUserId');
  }

  /// Stops listening for incoming calls.
  @override
  void stopListeningForCalls() {
    _callListenerRef?.onValue.drain();
    _callListenerRef = null;
    debugPrint('FirebaseCallService: Stopped RTDB listener.');
  }

  @override
  void dispose() {
    stopListeningForCalls();
    super.dispose();
  }
}