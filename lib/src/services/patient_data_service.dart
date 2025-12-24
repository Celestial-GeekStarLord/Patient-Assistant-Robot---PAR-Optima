// TODO Implement this library.
// lib/src/services/patient_data_service.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';

// The main database path for a specific patient/room (e.g., patient 402)
const String patientPath = 'room_402';

class PatientDataService extends ChangeNotifier {
  // Reference to the patient's root node in Firebase RTDB
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref(patientPath);

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

  // -------------------------
  // 3. CONSTRUCTOR & LISTENERS
  // -------------------------

  PatientDataService() {
    _listenToDatabase();
  }

  void _listenToDatabase() {
    // Listen to the main node for changes (vitals, state, robot status)
    _dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
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
          _callStatus =
              robot['callStatus']?.toString() ??
              _callStatus; // Can be updated by Patient or Robot
        }

        // Notify UI of any changes
        notifyListeners();
      }
    });
  }

  // -------------------------
  // 4. MUTATORS / COMMANDS (Write to Firebase)
  // -------------------------

  // --- A. PATIENT & ROBOT COMMANDS ---

  /// Triggered by the Patient Dashboard or Robot Interface.
  /// Notifies staff immediately.
  Future<void> setEmergency(bool isPending) async {
    // Patient or Robot Emergency Alert
    await _dbRef.child('state').update({
      'emergency': isPending,
      'lastEmergencyTime': isPending ? DateTime.now().toIso8601String() : null,
    });
    // This immediately updates the Staff Dashboard via the listener
  }

  /// Triggered by the Patient Dashboard (Call Robot button).
  /// This sets a command that the Robot Interface/Server will pick up.
  Future<void> requestRobot(String patientRoomID) async {
    await _dbRef.child('robot').update({
      'command': 'DISPATCH_TO_$patientRoomID',
      'lastRequestTime': DateTime.now().toIso8601String(),
    });
  }

  /// Triggered by the Patient or Robot when initiating a video call.
  Future<void> setCallStatus(String status) async {
    // status can be "Patient Calling", "Robot Calling", or "Idle"
    await _dbRef.child('robot').update({'callStatus': status});
  }

  // --- B. STAFF COMMANDS ---

  /// Triggered by the Staff Interface to resolve an emergency.
  Future<void> resolveEmergency() async {
    // Only staff can set this back to false
    await _dbRef.child('state').update({'emergency': false});
  }

  /// Triggered by the Staff Interface to update the next medication time.
  Future<void> setNextMedication(String time) async {
    await _dbRef.child('state').update({'nextMeds': time});
  }

  // --- C. ROBOT INTERFACE COMMANDS ---

  /// Triggered by the Robot Interface when staff manually selects a target.
  Future<void> dispatchRobotToRoom(String roomID) async {
    // This updates the robot's status and target simultaneously
    await _dbRef.child('robot').update({
      'status': 'Dispatching to $roomID',
      'targetRoom': roomID,
    });
  }
}
