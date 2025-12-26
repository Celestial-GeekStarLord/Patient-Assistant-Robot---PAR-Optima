// lib/src/services/patient_data_service.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';

class PatientDataService extends ChangeNotifier {

  // 🛑 Private field to store the initialization path
  final String _channelId;

  // Reference to the patient's root node in Firebase RTDB
  late final DatabaseReference _dbRef;

  // 🛑 Central RTDB path for robot commands (The robot listens here)
  static const String _robotCmdPath = 'cmd';

  // 🛑 NEW: Global Reference to the patient root, needed for staff monitoring
  static const String _patientRootPath = 'patients';

  // -------------------------
  // 1. DATA PROPERTIES (Synchronized from Firebase)
  // -------------------------

  // Vitals Data (Reported by sensors/robot)
  String _heartRate = "75";
  String _temperature = "98.6";
  String _oxygenSat = "99";

  // Patient State (Shared)
  bool _emergencyPending = false; // Triggered by Patient/Robot

  // 🛑 NEW: Medication fields for calculation
  Map<String, dynamic>? _medicationData;
  DateTime? _nextMedicationTime; // The calculated earliest time

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
  bool get emergencyPending => _emergencyPending;
  String? get robotStatus => _robotStatus;
  String? get callStatus => _callStatus;

  // 🛑 NEW GETTER: Calculated next medication time
  DateTime? get nextMedicationTime => _nextMedicationTime;

  // Public getter to expose the channel ID for external checking
  String get channelId => _channelId;

  // -------------------------
  // 3. CONSTRUCTOR & LISTENERS
  // -------------------------

  PatientDataService({required String channelId}) : _channelId = channelId {
    // Initialize the dynamic reference
    _dbRef = FirebaseDatabase.instance.ref(_channelId);
    _listenToDatabase();
    debugPrint('PatientDataService initialized for channel: $_channelId');
  }

  void _listenToDatabase() {

    // Listen to the main node for changes (vitals, state, robot status, medication)
    _dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        debugPrint('RTDB Update received for ${_dbRef.path}: $data');

        // Parse Vitals
        final vitals = data['vitals'] as Map<dynamic, dynamic>?;
        if (vitals != null) {
          // Note: Assuming RTDB stores these keys as 'hr', 'temp', 'o2'
          _heartRate = vitals['hr']?.toString() ?? _heartRate;
          _temperature = vitals['temp']?.toString() ?? _temperature;
          _oxygenSat = vitals['o2']?.toString() ?? _oxygenSat;
        }

        // Parse Shared State
        final state = data['state'] as Map<dynamic, dynamic>?;
        if (state != null) {
          _emergencyPending = state['emergency'] as bool? ?? _emergencyPending;
        }

        // 🛑 NEW: Parse Medication Data and trigger calculation
        // Ensure keys are correctly cast as String
        _medicationData = data['medication']?.cast<String, dynamic>() as Map<String, dynamic>?;
        _calculateNextMedicationTime();

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

  // 🛑 NEW METHOD: Logic to calculate the earliest next dose (FINAL FIX)
  void _calculateNextMedicationTime() {
    if (_medicationData == null || _medicationData!.isEmpty) {
      _nextMedicationTime = null;
      debugPrint('Medication data is empty or null.');
      return;
    }

    DateTime? earliestNextTime;
    final now = DateTime.now();

    // Iterate over each medication
    _medicationData!.forEach((key, value) {
      // Ensure values are correct types and not null
      final frequency = value['frequency_hours'] as int?;
      final lastAdministeredMillis = value['last_administered'] as int?;

      if (frequency != null && lastAdministeredMillis != null) {
        final lastAdministered = DateTime.fromMillisecondsSinceEpoch(lastAdministeredMillis);

        // Calculate the scheduled next time (last administered + frequency)
        DateTime nextScheduledTime = lastAdministered.add(Duration(hours: frequency));

        // 🛑 FINAL FIX: Use a local variable to hold the existing time if it exists.
        final currentEarliest = earliestNextTime;

        if (currentEarliest == null || nextScheduledTime.isBefore(currentEarliest)) {
          earliestNextTime = nextScheduledTime;
        }
      }
    });

    _nextMedicationTime = earliestNextTime;

    // 🛑 LOGGING: Calculate and show remaining time in minutes
    // Use the null-aware access operator (?.) and if-case for clarity
    if (earliestNextTime case final time?) {
      // time is now guaranteed non-nullable DateTime
      final difference = time.difference(now);
      final totalMinutes = difference.inMinutes;
      final isOverdue = totalMinutes.isNegative;

      String logMessage;

      if (isOverdue) {
        logMessage = 'Medication is OVERDUE by ${totalMinutes.abs()} minutes.';
      } else {
        logMessage = 'Next critical medication time is in $totalMinutes minutes.';
      }

      // The 'toLocal()' call is now safe.
      debugPrint('Calculated next critical medication: $logMessage (Time: ${time.toLocal()})');
    }
  }


  // 🛑 NEW: Staff Monitoring Method
  /// Returns a stream to monitor the entire 'patient' root node.
  Stream<DatabaseEvent> watchAllPatientStates() {
    return FirebaseDatabase.instance.ref(_patientRootPath).onValue;
  }

  // -------------------------
  // 4. MUTATORS / COMMANDS (Write to Firebase)
  // -------------------------

  // 🛑 UPDATED: Initializes a specific command structure for testing/setup
  Future<void> initializeRobotCommandsForTesting() async {
    final Map<String, dynamic> payload = {
      'cmd': 'start',
      'w': 'forward',
      'a': 'left',
      's': 'backward',
      'timestamp': ServerValue.timestamp,
    };

    try {
      // Write to the simplified root endpoint 'cmd'
      await FirebaseDatabase.instance.ref(_robotCmdPath).set(payload);
      debugPrint('Robot Command INITIALIZED: Sent specific cmd list (start, w, a, s) to $_robotCmdPath');
    } catch (e) {
      debugPrint('ERROR initializing robot commands: $e');
    }
  }


  // --- A. PATIENT & ROBOT COMMANDS ---

  /// Triggered by the Patient Dashboard or Robot Interface.
  /// Notifies staff immediately.
  Future<void> setEmergency(bool isPending) async {
    await _dbRef.child('state').update({
      'emergency': isPending,
      'lastEmergencyTime': isPending ? ServerValue.timestamp : null,
    });
    debugPrint('Command: Set emergency to $isPending for ${_dbRef.path}');
  }

  /// Triggered by the Patient Dashboard (Call Robot button).
  /// Sends room-specific character command to the central command node.
  Future<void> requestRobot(String roomNumber) async {
    // 1. Normalize the room identifier (e.g., '401' -> 'room_401')
    final String channelId = 'room_${roomNumber.toLowerCase().replaceAll(' ', '')}';

    // 2. Determine the command based on the channel/room ID
    String robotCommand;
    String statusUpdate;
    switch (channelId) {
      case 'room_401':
        robotCommand = 'w'; // Example: Forward command
        statusUpdate = 'Dispatching to Room 401 (w)';
        break;
      case 'room_402':
        robotCommand = 'a'; // Example: Left command
        statusUpdate = 'Dispatching to Room 402 (a)';
        break;
      case 'room_403':
        robotCommand = 's'; // Example: Backward/Stop command
        statusUpdate = 'Dispatching to Room 403 (s)';
        break;
      default:
        debugPrint('Warning: No specific command map for room: $channelId. Sending default stop.');
        robotCommand = 'x'; // Default or stop command
        statusUpdate = 'Dispatching to $roomNumber (default)';
    }

    // 3. Construct the payload for the CENTRAL Firebase command node
    final Map<String, dynamic> payload = {
      // The robot client expects the actual command here, which is 'w', 'a', or 's'
      'data': robotCommand,
      'target_room': channelId,
      'timestamp': ServerValue.timestamp,
    };

    try {
      // 4. Send the command to the *central* endpoint 'cmd'
      await FirebaseDatabase.instance.ref(_robotCmdPath).set(payload);
      debugPrint('Robot Command SENT: Room $channelId, Command $robotCommand');

      // 5. Update the *patient's local* node to reflect the dispatch status in the UI
      await _dbRef.child('robot').update({
        'status': statusUpdate,
        'lastRequestTime': ServerValue.timestamp,
      });

    } catch (e) {
      debugPrint('ERROR sending robot command: $e');
    }
  }


  /// Triggered by the Patient or Robot when initiating a video call.
  Future<void> setCallStatus(String status) async {
    // status can be "Patient Calling", "Robot Calling", or "Idle"
    await _dbRef.child('robot').update({'callStatus': status});
    debugPrint('Command: Set call status to $status');
  }

  // --- B. STAFF COMMANDS ---

  /// Triggered by the Staff Interface to resolve an emergency for a specific patient.
  Future<void> clearEmergency(String customId) async {
    final targetRef = FirebaseDatabase.instance.ref('$_patientRootPath/$customId/state');
    await targetRef.update({'emergency': false});
    debugPrint('Command: Resolved emergency for patient $customId');
  }

  /// Triggered by the Staff Interface to resolve an emergency.
  Future<void> resolveEmergency() async {
    await _dbRef.child('state').update({'emergency': false});
    debugPrint('Command: Resolved emergency for ${_dbRef.path}');
  }

  /// Triggered by the Staff Interface to update the next medication time.
  /// 🛑 MODIFIED: This now updates the medication schedule by setting a 'last_administered' time,
  /// which automatically triggers the calculation in the listener.
  Future<void> administerMedication(String medicationKey) async {
    // We assume the medicationKey is the key in the 'medication' map (e.g., 'med1_paracetamol')
    await _dbRef.child('medication').child(medicationKey).update({
      'last_administered': ServerValue.timestamp,
    });
    debugPrint('Command: Administered medication $medicationKey at ${DateTime.now().toLocal()}');
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