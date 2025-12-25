// // lib/src/services/call_service.dart
//
// import 'package:flutter/foundation.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// import '../models/call_model.dart';
// import '../providers/user_provider.dart';
//
// // -----------------------------------------------------------------------------
// // IMPORTANT: Replace these with your actual Agora App ID and Token Server URL
// // -----------------------------------------------------------------------------
// const String agoraAppId = 'YOUR_AGORA_APP_ID';
// // In a real app, this should be a secure backend endpoint (e.g., Firebase Function)
// const String tokenServerUrl = 'YOUR_TOKEN_SERVER_URL';
// // -----------------------------------------------------------------------------
//
// class CallService with ChangeNotifier {
//   // Base reference for all calls. Calls will be structured under /calls/{userId}
//   final DatabaseReference _callsRef = FirebaseDatabase.instance.ref('calls');
//
//   // Stores the currently ringing/active call object for the local user
//   CallModel? _currentCall;
//
//   // Stores the Agora token once fetched
//   String? _agoraToken;
//
//   CallModel? get currentCall => _currentCall;
//   String? get agoraToken => _agoraToken;
//
//   // Stores the listener subscription reference
//   DatabaseReference? _callListenerRef;
//
//   /// Initializes the service and starts listening for incoming calls for the local user.
//   void startListeningForCalls(String localUserId) {
//     if (localUserId.isEmpty || _callListenerRef != null) return;
//
//     // Listen to the Firebase RTDB node dedicated to this user's incoming calls.
//     _callListenerRef = _callsRef.child(localUserId);
//
//     _callListenerRef!.onValue.listen((event) {
//       final data = event.snapshot.value as Map<dynamic, dynamic>?;
//
//       if (data != null) {
//         final Map<String, dynamic> mapData = Map<String, dynamic>.from(data);
//         final CallModel call = CallModel.fromMap(mapData);
//
//         // Update state if the received data is a valid call
//         _currentCall = call;
//         notifyListeners();
//         debugPrint('CallService: Received call update. Status: ${_currentCall?.status}');
//
//       } else {
//         // Node was cleared (call ended by remote party)
//         if (_currentCall != null) {
//           debugPrint('CallService: Call ended/cleared by remote party.');
//           _currentCall = null;
//           _agoraToken = null;
//           notifyListeners();
//         }
//       }
//     }).onError((error) {
//       debugPrint('Call Listener Error for $localUserId: $error');
//     });
//
//     debugPrint('CallService: Started listening for calls on path calls/$localUserId');
//   }
//
//   /// Fetches an Agora token from a backend server.
//   Future<String?> _fetchAgoraToken(String channelName, int uid) async {
//     // 🛑 WARNING: Using a placeholder token for development.
//     // This MUST be replaced by a secure HTTP request to your Token Server.
//     if (tokenServerUrl == 'YOUR_TOKEN_SERVER_URL') {
//       // Return a temporary token (must be pre-generated for your Agora App ID)
//       const String temporaryTestToken = '007eJxTYPhgLaWbt9T3keCr8xqrzhxJZOo5dvyax1wG/tkzo87vVpmjwGCZamRqmWRumGRikWaSbGhqmWJkZmBmmWZqaW5qZJhmoeDjk9kQyMhwn8OQhZEBAkF8Doai/PzceBMDIwYGAKjFHvw=';
//       return temporaryTestToken;
//     }
//
//     // 🛑 Uncomment the below code for production use with a token server
//     /*
//     try {
//       final response = await http.get(
//         Uri.parse('$tokenServerUrl/rtc/$channelName/publisher/uid/$uid/'),
//       );
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         return data['token'];
//       } else {
//         debugPrint('Token Server error: ${response.statusCode}');
//         return null;
//       }
//     } catch (e) {
//       debugPrint('HTTP request failed: $e');
//       return null;
//     }
//     */
//   }
//
//   /// Initiates a call by writing the call model to the receiver's RTDB node.
//   Future<bool> makeCall({
//     required UserProvider caller,
//     required String receiverId,
//     required String receiverName
//   }) async {
//     if (caller.userCustomId == null || caller.userChannelId == null || caller.userName == null) {
//       debugPrint('CallService: Caller ID/Channel not available.');
//       return false;
//     }
//
//     // Create a unique channel ID (Agora Channel Name)
//     final String channelName = '${caller.userChannelId!}_call';
//
//     // 1. Fetch Agora Token (using UID 0 to let Agora assign)
//     final String? token = await _fetchAgoraToken(channelName, 0);
//     if (token == null) {
//       debugPrint('CallService: Failed to fetch Agora token.');
//       return false;
//     }
//     _agoraToken = token;
//
//     // 2. Build the Call Model
//     final CallModel newCall = CallModel(
//       callerId: caller.userCustomId!,
//       callerName: caller.userName!,
//       receiverId: receiverId, // Staff ID
//       receiverName: receiverName, // Staff Name
//       channelId: channelName,
//       status: 'ringing',
//       isRobot: false, // The Patient is initiating the call
//     );
//
//     _currentCall = newCall;
//
//     // 3. Write the call data to the receiver's call node in RTDB
//     // This makes the call visible to the staff interface
//     await _callsRef.child(receiverId).set(newCall.toMap());
//
//     notifyListeners();
//     debugPrint('CallService: Initiated call to $receiverName on channel $channelName');
//     return true;
//   }
//
//   /// Called by the receiver (Patient or Staff) to accept an incoming call.
//   Future<void> acceptCall() async {
//     if (_currentCall == null) return;
//
//     // 1. Update the call status to 'accepted' in the RTDB node
//     await _callsRef.child(_currentCall!.receiverId).update({'status': 'accepted'});
//
//     // 2. Update local state
//     _currentCall = _currentCall!.copyWith(status: 'accepted');
//
//     // 3. Fetch token for receiver (if not already done by the UI navigating to the call screen)
//     if (_agoraToken == null) {
//       final String? token = await _fetchAgoraToken(_currentCall!.channelId, 0);
//       _agoraToken = token;
//       debugPrint('CallService: Receiver fetched Agora token.');
//     }
//
//     notifyListeners();
//   }
//
//   /// Called by either party to end the call. Clears the RTDB node.
//   Future<void> endCall() async {
//     if (_currentCall == null) return;
//
//     // Store the receiver ID before clearing the local model
//     final String receiverId = _currentCall!.receiverId;
//     final String callerId = _currentCall!.callerId;
//
//     // 1. Clear the call from the receiver's node (this triggers listener on all clients)
//     await _callsRef.child(receiverId).remove();
//
//     // 2. Clear the call from the caller's node (redundant if using the receiver node as main signal, but safe)
//     await _callsRef.child(callerId).remove();
//
//     // 3. Clear local state
//     _currentCall = null;
//     _agoraToken = null;
//     notifyListeners();
//     debugPrint('CallService: Call ended and cleared from Firebase.');
//   }
//
//   /// Clears the service and stops the listener. Called when the service is no longer needed (e.g., user logs out).
//   void stopListeningForCalls() {
//     // Note: Due to Firebase SDK limitations, there is no direct way to cancel
//     // a non-StreamSubscription listener, but clearing the reference is a good step.
//     _callListenerRef = null;
//     _currentCall = null;
//     _agoraToken = null;
//     notifyListeners();
//     debugPrint('CallService: Stopped listening for calls.');
//   }
//
//   @override
//   void dispose() {
//     // In a production app, you would need to manage the StreamSubscription to properly cancel it.
//     // Since we used .onValue.listen() without storing the subscription,
//     // we rely on the object being garbage collected or the user logging out.
//     stopListeningForCalls();
//     super.dispose();
//   }
// }

// lib/src/services/call_service.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
// import 'package:http/http.dart' as http; // NO LONGER NEEDED
// import 'dart:convert'; // NO LONGER NEEDED

import '../models/call_model.dart';
import '../providers/user_provider.dart';

// -----------------------------------------------------------------------------
// 🛑 HACKATHON TEMPORARY CONFIGURATION 🛑
// 1. Get a temporary token from your Agora Console for TESTING.
// 2. Use a fixed, simple channel name for both users.
// -----------------------------------------------------------------------------
const String agoraAppId = '2ee772e621bb4a7097d129349fc808bc';
// Use a fixed channel name that both the caller and receiver will use to join.
const String tempChannelName = 'hackathon_channel';
// **REPLACE THIS** with the token you generated from the Agora Console!
const String temporaryTestToken = '007eJxTYAhoZTOddF9s9r406eWbfznIR2S4qUxp/F7J+y+2Wi5xw1EFBqPUVHNzo1QzI8OkJJNEcwNL8xRDI0tjE8u0ZAsDi6TkEFHfzIZARob2V26MjAwQCOILMmQkJmcnlmTk58UnZyTm5aXmMDAAAIgFIvw=';
// -----------------------------------------------------------------------------

class CallService with ChangeNotifier {
  // Base reference for all calls. Calls will be structured under /calls/{userId}
  final DatabaseReference _callsRef = FirebaseDatabase.instance.ref('calls');

  // Stores the currently ringing/active call object for the local user
  CallModel? _currentCall;

  // Stores the Agora token once fetched
  String? _agoraToken;

  CallModel? get currentCall => _currentCall;
  String? get agoraToken => _agoraToken;

  // Stores the listener subscription reference
  DatabaseReference? _callListenerRef;

  /// Initializes the service and starts listening for incoming calls for the local user.
  void startListeningForCalls(String localUserId) {
    if (localUserId.isEmpty || _callListenerRef != null) return;

    // Listen to the Firebase RTDB node dedicated to this user's incoming calls.
    _callListenerRef = _callsRef.child(localUserId);

    // ... (rest of the startListeningForCalls function is unchanged) ...

    _callListenerRef!.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        final Map<String, dynamic> mapData = Map<String, dynamic>.from(data);
        final CallModel call = CallModel.fromMap(mapData);

        // Update state if the received data is a valid call
        _currentCall = call;
        notifyListeners();
        debugPrint('CallService: Received call update. Status: ${_currentCall?.status}');

      } else {
        // Node was cleared (call ended by remote party)
        if (_currentCall != null) {
          debugPrint('CallService: Call ended/cleared by remote party.');
          _currentCall = null;
          _agoraToken = null;
          notifyListeners();
        }
      }
    }).onError((error) {
      debugPrint('Call Listener Error for $localUserId: $error');
    });

    debugPrint('CallService: Started listening for calls on path calls/$localUserId');
  }

  /// Fetches an Agora token from a backend server.
  Future<String?> _fetchAgoraToken(String channelName, int uid) async {
    // 🛑 HACKATHON FIX: Return the hardcoded temporary token instantly.
    return temporaryTestToken;

    // The original token server logic is commented out/removed.
  }

  /// Initiates a call by writing the call model to the receiver's RTDB node.
  Future<bool> makeCall({
    required UserProvider caller,
    required String receiverId,
    required String receiverName
  }) async {
    if (caller.userCustomId == null || caller.userName == null) {
      debugPrint('CallService: Caller ID/Name not available.');
      return false;
    }

    // 🛑 HACKATHON FIX: Use the hardcoded channel name instead of generating a unique one.
    final String channelName = tempChannelName;

    // 1. Fetch Agora Token
    final String? token = await _fetchAgoraToken(channelName, 0);
    if (token == null) {
      debugPrint('CallService: Failed to fetch Agora token (Should not happen with temporary token).');
      return false;
    }
    _agoraToken = token;

    // 2. Build the Call Model
    final CallModel newCall = CallModel(
      callerId: caller.userCustomId!,
      callerName: caller.userName!,
      receiverId: receiverId, // Staff ID
      receiverName: receiverName, // Staff Name
      channelId: channelName, // Use the fixed hackathon channel
      status: 'ringing',
      isRobot: false, // The Patient is initiating the call
    );

    _currentCall = newCall;

    // 3. Write the call data to the receiver's call node in RTDB
    await _callsRef.child(receiverId).set(newCall.toMap());

    notifyListeners();
    debugPrint('CallService: Initiated call to $receiverName on FIXED channel $channelName');
    return true;
  }

  /// Called by the receiver (Patient or Staff) to accept an incoming call.
  Future<void> acceptCall() async {
    if (_currentCall == null) return;

    // 1. Update the call status to 'accepted' in the RTDB node
    await _callsRef.child(_currentCall!.receiverId).update({'status': 'accepted'});

    // 2. Update local state
    _currentCall = _currentCall!.copyWith(status: 'accepted');

    // 3. Fetch token for receiver (if not already done by the UI navigating to the call screen)
    if (_agoraToken == null) {
      // 🛑 HACKATHON FIX: Directly use the hardcoded token
      _agoraToken = temporaryTestToken;
      debugPrint('CallService: Receiver used hardcoded Agora token.');
    }

    notifyListeners();
  }

  /// Called by either party to end the call. Clears the RTDB node.
  Future<void> endCall() async {
    if (_currentCall == null) return;

    // ... (rest of endCall function is unchanged) ...

    // Store the receiver ID before clearing the local model
    final String receiverId = _currentCall!.receiverId;
    final String callerId = _currentCall!.callerId;

    // 1. Clear the call from the receiver's node (this triggers listener on all clients)
    await _callsRef.child(receiverId).remove();

    // 2. Clear the call from the caller's node (redundant if using the receiver node as main signal, but safe)
    await _callsRef.child(callerId).remove();

    // 3. Clear local state
    _currentCall = null;
    _agoraToken = null;
    notifyListeners();
    debugPrint('CallService: Call ended and cleared from Firebase.');
  }

  /// Clears the service and stops the listener. Called when the service is no longer needed (e.g., user logs out).
  void stopListeningForCalls() {
    // ... (content remains the same) ...
    _callListenerRef = null;
    _currentCall = null;
    _agoraToken = null;
    notifyListeners();
    debugPrint('CallService: Stopped listening for calls.');
  }

  @override
  void dispose() {
    stopListeningForCalls();
    super.dispose();
  }
}