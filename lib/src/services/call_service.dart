// lib/src/services/call_service.dart

import 'package:flutter/foundation.dart';

// Assume these models/providers are defined in their respective files:
import '../models/call_model.dart';
import '../providers/user_provider.dart';

// --------------------------------------------------------------------
// 1. CALL STATUS ENUM
// Defines the possible states of a call connection.
// --------------------------------------------------------------------

/// Possible states for a call transaction.
enum CallStatus {
  idle,       // No call active, service is listening/waiting
  ringing,    // Outbound call is waiting for an answer, or inbound call is ringing
  connected,  // Call is active and streaming via Agora
  missed,     // Call was missed
  busy,       // Callee is already in a call
}

// --------------------------------------------------------------------
// 2. ABSTRACT CALL SERVICE INTERFACE
// Defines the contract that concrete services must implement.
// --------------------------------------------------------------------

/// Defines the contract for any service responsible for managing the call state and signaling.
///
/// Any concrete class implementing this interface (like FirebaseCallService) must mix in ChangeNotifier.
abstract class CallService with ChangeNotifier {

  // --- State Properties (Must be implemented as getters in concrete class) ---

  /// The current state of the call (Idle, Ringing, Connected, etc.)
  CallStatus get status;

  /// The model representing the current call, if one is active.
  CallModel? get currentCall;

  /// The token required to join the Agora channel.
  String? get agoraToken;

  /// Indicates if the service is initialized and ready for use.
  bool get isReady;


  // --- Core Signaling Methods ---

  /// Initiates an outbound call to a receiver by setting the 'ringing' state in the database.
  /// Called by the Patient/Robot.
  /// Returns true if the signaling message was sent successfully.
  Future<bool> makeCall({
    required UserProvider caller,
    required String receiverId,
    required String receiverName
  });

  /// Accepts an incoming call, updates the database state, and prepares the Agora call.
  /// Called by the Staff.
  Future<void> acceptCall();

  /// Ends the call, clears the database node, and stops Agora stream.
  /// Called by both parties.
  Future<void> declineCall();


  // --- Listener Management ---

  /// Starts listening for incoming call signals on the local user's ID via Firebase.
  /// Called by the Staff interface upon login.
  void startListeningForCalls(String localUserId);

  /// Stops listening for incoming calls.
  void stopListeningForCalls();
}