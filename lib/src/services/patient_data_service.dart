// lib/src/services/patient_data_service.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';

class PatientDataService extends ChangeNotifier {

  // 🛑 FIX: Private field to store the initialization path
  final String _channelId;

  // Reference to the patient's root node in Firebase RTDB
  late final DatabaseReference _dbRef;

  // Storage for the subscription to keep the stream active and allow unsubscribing.
  DatabaseReference? _activeRef; // Note: This field is unused without proper stream disposal logic.

  // -------------------------
  // 1. DATA PROPERTIES (Synchronized from Firebase)
  // -------------------------

  // Vitals Data (Reported by sensors/robot)
  String _heartRate = "75";
  String _temperature = "98.6";
  String _oxygenSat = "99";

  // Patient State (Shared)
  String _nextMedsTime = "N/A";
  bool _emergencyPending = false; // Triggered by Patient/Robot

  // Robot Status (Reported by Robot Interface)
  String? _robotStatus = "Idle"; // e.g., "Idle", "Dispatching to Room 402"

  // Call Status (Used for Staff Interface to pickup calls)
  String? _callStatus =
      "Idle"; // e.g., "Idle", "Patient Calling", "Robot Calling"

  // -------------------------
  // 2. GETTERS
  // -------------------------

  String get heartRate => _heartRate;
  String get temperature => _temperature;
  String get oxygenSat => _oxygenSat;
  String get nextMedsTime => _nextMedsTime;
  bool get emergencyPending => _emergencyPending;
  String? get robotStatus => _robotStatus;
  String? get callStatus => _callStatus;

  // 🛑 FIX: Public getter to expose the channel ID for external checking (e.g., in ProxyProvider)
  String get channelId => _channelId;

  // -------------------------
  // 3. CONSTRUCTOR & LISTENERS
  // -------------------------

  // 🛑 CONSTRUCTOR: Takes the dynamic channelId and initializes the field
  PatientDataService({required String channelId}) : _channelId = channelId {
    // Initialize the dynamic reference
    _dbRef = FirebaseDatabase.instance.ref(_channelId);
    _listenToDatabase();
    debugPrint('PatientDataService initialized for channel: $_channelId');
  }

  void _listenToDatabase() {
    _activeRef = _dbRef; // Store the reference

    // Listen to the main node for changes (vitals, state, robot status)
    _dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        debugPrint('RTDB Update received for ${_dbRef.path}: $data');

        // Parse Vitals
        final vitals = data['vitals'] as Map<dynamic, dynamic>?;
        if (vitals != null) {
          _heartRate = vitals['hr']?.toString() ?? _heartRate;
          _temperature = vitals['temp']?.toString() ?? _temperature;
          _oxygenSat = vitals['o2']?.toString() ?? _oxygenSat;
        }

        // Parse Shared State
        final state = data['state'] as Map<dynamic, dynamic>?;
        if (state != null) {
          _nextMedsTime = state['nextMeds']?.toString() ?? _nextMedsTime;
          _emergencyPending = state['emergency'] as bool? ?? _emergencyPending;
        }

        // Parse Robot Status
        final robot = data['robot'] as Map<dynamic, dynamic>?;
        if (robot != null) {
          _robotStatus = robot['status']?.toString() ?? _robotStatus;
          _callStatus = robot['callStatus']?.toString() ?? _callStatus;
        }

        // Notify UI of any changes
        notifyListeners();
      }
    }).onError((error) {
      debugPrint('RTDB Listener Error: $error');
    });
  }

  // -------------------------
  // 4. MUTATORS / COMMANDS (Write to Firebase)
  // -------------------------

  // --- A. PATIENT & ROBOT COMMANDS ---

  /// Triggered by the Patient Dashboard or Robot Interface.
  /// Notifies staff immediately.
  Future<void> setEmergency(bool isPending) async {
    // Note: This method no longer takes 'channelId' as it uses the instance's '_dbRef'.
    await _dbRef.child('state').update({
      'emergency': isPending,
      'lastEmergencyTime': isPending ? ServerValue.timestamp : null, // Use ServerValue for accurate time
    });
    debugPrint('Command: Set emergency to $isPending for ${_dbRef.path}');
  }

  /// Triggered by the Patient Dashboard (Call Robot button).
  Future<void> requestRobot() async {
    final String roomID = _dbRef.key ?? 'UNKNOWN_ROOM';
    await _dbRef.child('robot').update({
      'command': 'DISPATCH_TO_$roomID',
      'lastRequestTime': ServerValue.timestamp, // Use ServerValue for accurate time
    });
    debugPrint('Command: Requested robot for room $roomID');
  }

  /// Triggered by the Patient or Robot when initiating a video call.
  Future<void> setCallStatus(String status) async {
    // status can be "Patient Calling", "Robot Calling", or "Idle"
    await _dbRef.child('robot').update({'callStatus': status});
    debugPrint('Command: Set call status to $status');
  }

  // --- B. STAFF COMMANDS ---

  /// Triggered by the Staff Interface to resolve an emergency.
  Future<void> resolveEmergency() async {
    await _dbRef.child('state').update({'emergency': false});
    debugPrint('Command: Resolved emergency for ${_dbRef.path}');
  }

  /// Triggered by the Staff Interface to update the next medication time.
  Future<void> setNextMedication(String time) async {
    await _dbRef.child('state').update({'nextMeds': time});
    debugPrint('Command: Set next medication time to $time');
  }

  // --- C. ROBOT INTERFACE COMMANDS ---

  /// Triggered by the Robot Interface when staff manually selects a target.
  Future<void> dispatchRobotToRoom(String roomID) async {
    // This updates the robot's status and target simultaneously
    await _dbRef.child('robot').update({
      'status': 'Dispatching to $roomID',
      'targetRoom': roomID,
      'command': 'DISPATCH_TO_$roomID',
    });
    debugPrint('Command: Dispatched robot to room $roomID');
  }
}