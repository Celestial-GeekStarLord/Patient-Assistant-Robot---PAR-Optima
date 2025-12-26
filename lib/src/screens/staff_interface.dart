// lib/src/screens/staff_interface.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart'; // Needed for DatabaseEvent

// REQUIRED CALL/LOGIC IMPORTS
import '../providers/user_provider.dart';
import '../services/firebase_call_service.dart';
import '../services/call_service.dart'; // For CallStatus enum
import '../services/communication_service.dart';
import '../services/patient_data_service.dart'; // CRITICAL: Now used for multi-patient stream

// SCREEN IMPORTS
import 'video_call_screen.dart';
import 'patient_details_page.dart';
import 'account.dart'; // Needed for AccountMenu

// CONVERTED TO STATEFULWIDGET
class StaffInterface extends StatefulWidget {
  const StaffInterface({super.key});

  @override
  State<StaffInterface> createState() => _StaffInterfaceState();
}

class _StaffInterfaceState extends State<StaffInterface> {
  // 🛑 CRITICAL: Common ID for all staff to listen on (Broadcast Model)
  static const String COMMON_STAFF_LISTEN_ID = 'staff_group_station';

  // Fallback ID for Agora UID generation.
  static const String FALLBACK_STAFF_ID = 'staff_101';

  // --- MODERN UI COLOR PALETTE ---
  final Color primaryNavy = const Color(0xFF0D47A1);
  final Color accentBlue = const Color(0xFF1976D2);
  final Color bgGrey = const Color(0xFFF8FAFC);
  final Color redAlert = Colors.red[700]!;

  // 🛑 NEW STATE: To track an active emergency from ANY patient
  String? _activeEmergencyId; // Stores the patient ID (e.g., 'P123') in emergency

  @override
  void initState() {
    super.initState();
    // Start the call listener and the emergency listener after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCallListener(context);
      // 🛑 NEW: Start the multi-patient emergency database listener
      _startEmergencyListener(context);
    });
  }

  // --- LOGIC: EMERGENCY LISTENER SETUP ---
  void _startEmergencyListener(BuildContext context) {
    try {
      final patientDataService = Provider.of<PatientDataService>(context, listen: false);

      // Listen to the root 'patient' node for changes across all patients
      patientDataService.watchAllPatientStates().listen((DatabaseEvent event) {
        if (!mounted || event.snapshot.value == null) return;

        final Map<dynamic, dynamic>? patientsData = event.snapshot.value as Map?;
        if (patientsData == null) return;

        String? newEmergencyPatientId;

        // Iterate through all patients to find the active emergency
        patientsData.forEach((key, value) {
          final state = value['state'] as Map<dynamic, dynamic>?;
          if (state != null && state['emergency'] == true) {
            newEmergencyPatientId = key.toString(); // Found an active emergency
          }
        });

        // Update UI state if the emergency status has changed
        if (newEmergencyPatientId != _activeEmergencyId) {
          setState(() {
            _activeEmergencyId = newEmergencyPatientId;
          });

          if (_activeEmergencyId != null) {
            // Trigger the modal alert only when a NEW emergency is found
            _showAlert(context, _activeEmergencyId!);
          }
        }
      }).onError((error) {
        debugPrint('RTDB Multi-Patient Listener Error: $error');
      });
    } catch (e) {
      debugPrint('ERROR: Failed to start emergency listener. Error: $e');
    }
  }

  // --- ALERT DIALOG HANDLERS ---

  void _showAlert(BuildContext context, String patientId) {
    // If the call ringing overlay is already showing, avoid stacking dialogs,
    // but ensure the red emergency banner is visible below.
    if (context.read<FirebaseCallService>().status == CallStatus.ringing) {
      return;
    }

    // Dismiss the previous alert if necessary
    if (Navigator.canPop(context) && ModalRoute.of(context)!.isCurrent == false) {
      Navigator.pop(context);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.red[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.red, size: 30),
              SizedBox(width: 10),
              Text("EMERGENCY ALERT!"),
            ],
          ),
          content: Text(
            "Patient $patientId requires IMMEDIATE assistance. Check details or accept the incoming call.",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => _acknowledgeAlert(context, patientId),
              style: ElevatedButton.styleFrom(backgroundColor: redAlert, elevation: 5),
              child: const Text("ACKNOWLEDGE & RESOLVE", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                // Just dismiss the dialog, leaving the status active
                Navigator.pop(ctx);
              },
              child: Text("VIEW LATER", style: TextStyle(color: primaryNavy)),
            ),
          ],
        );
      },
    );
  }

  void _acknowledgeAlert(BuildContext context, String patientId) {
    final patientDataService = context.read<PatientDataService>();

    // 1. Reset the database flag for the specific patient
    patientDataService.clearEmergency(patientId);

    // 2. Dismiss the local dialog
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    // 4. Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Emergency for Patient $patientId has been resolved in database.')),
    );
  }

  // --- END: EMERGENCY LISTENER SETUP ---

  // --- LOGIC: CALL LISTENER SETUP ---
  void _startCallListener(BuildContext context) {
    try {
      final firebaseCallService = Provider.of<FirebaseCallService>(context, listen: false);
      final String localListenId = COMMON_STAFF_LISTEN_ID;

      firebaseCallService.startListeningForCalls(localListenId);
      debugPrint('StaffInterface: Started listening for calls on COMMON ID $localListenId');
    } catch (e) {
      debugPrint('ERROR: Failed to start call listener. Ensure FirebaseCallService is provided. Error: $e');
    }
  }

  /// Handles the action when the Staff accepts the call (via the overlay).
  void _acceptIncomingCall(BuildContext context, FirebaseCallService callService) async {
    final commService = Provider.of<CommunicationService>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final currentCall = callService.currentCall;
    if (currentCall == null) return;

    // 1. Update Firebase status to 'accepted' (locks the call for the group)
    await callService.acceptCall();

    // 2. Staff joins the Agora channel
    final String staffIdentifier = userProvider.userCustomId ?? FALLBACK_STAFF_ID;
    final int staffUid = staffIdentifier.hashCode;

    await commService.joinCall(
      channelName: currentCall.channelId,
      userUid: staffUid,
    );

    // 3. Optional: If the call was an emergency, acknowledge the alert
    if (_activeEmergencyId != null && currentCall.channelId.contains('emergency')) {
      // Automatically resolve the emergency flag if the staff accepts the emergency call
      context.read<PatientDataService>().clearEmergency(_activeEmergencyId!);
      setState(() { _activeEmergencyId = null; });
    }


    // 4. Navigate to the call screen
    if (mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => VideoCallScreen(
          channelName: currentCall.channelId,
          isHost: true, // Staff is the Host (receiving side accepting control)
        ),
      ));
    }
  }

  /// Handles the action when the Staff declines the call.
  void _declineIncomingCall(FirebaseCallService callService) async {
    await callService.declineCall();
  }
  // --- END: CALL LISTENER SETUP ---


  // --- UI HELPER METHODS ---

  // --- POPUP MESSAGE (for "Call Robot to Station") ---
  void _showConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Robot Summoned"),
        content: const Text("The robot is on the way to your current location."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  // --- REUSABLE ACTION CARD DESIGN (Unchanged) ---
  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(20),
          backgroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: primaryNavy, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // 🛑 Multi-Patient Emergency Banner
  Widget _buildMultiPatientEmergencyBanner() {
    if (_activeEmergencyId == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: redAlert,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Text("EMERGENCY: Patient $_activeEmergencyId",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              // Action when the RESOLVE button on the banner is pressed
              _acknowledgeAlert(context, _activeEmergencyId!);
            },
            style: TextButton.styleFrom(backgroundColor: Colors.white),
            child: const Text("RESOLVE", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  // --- ROBOT STATUS FOOTER (Unchanged) ---
  Widget _buildRobotStatusFooter(PatientDataService data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryNavy,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.sensors_rounded, color: Colors.greenAccent),
              const SizedBox(width: 10),
              // NOTE: This status reflects the PatientDataService instance associated with this staff's primary patient.
              Text("Robot: ${data.robotStatus ?? 'Idle'}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const Text("88% (Battery)", style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  // --- RINGING OVERLAY (Unchanged) ---
  Widget _buildRingingOverlay(BuildContext context, FirebaseCallService callService) {
    if (callService.status != CallStatus.ringing) {
      return const SizedBox.shrink();
    }

    final callerName = callService.currentCall?.callerName ?? 'Patient/Robot';

    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(30),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone_in_talk, color: Colors.green, size: 50),
                  const SizedBox(height: 15),
                  const Text('INCOMING CALL', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('From: $callerName', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // DECLINE BUTTON
                      FloatingActionButton(
                        heroTag: 'decline',
                        onPressed: () => _declineIncomingCall(callService),
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.call_end, color: Colors.white, size: 30),
                      ),
                      // ACCEPT BUTTON
                      FloatingActionButton(
                        heroTag: 'accept',
                        onPressed: () => _acceptIncomingCall(context, callService),
                        backgroundColor: Colors.green,
                        child: const Icon(Icons.videocam, color: Colors.white, size: 30),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Watch providers for real-time updates
    final patientData = context.watch<PatientDataService>();
    final firebaseCallService = context.watch<FirebaseCallService>();
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: bgGrey,
      // --- APP BAR ---
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text('STAFF HUB',
            style: TextStyle(color: primaryNavy, fontWeight: FontWeight.w900, letterSpacing: 1)),
        centerTitle: false,
        actions: [
          //--- NOTIFICATION BUTTON (Badge shows if a call is ringing) ---
          IconButton(
            icon: Badge(
              label: Text(firebaseCallService.status == CallStatus.ringing ? '1' : '0'),
              child: Icon(Icons.notifications_none_rounded, color: primaryNavy),
            ),
            // If there's an emergency, prioritize showing the alert dialog on press
            onPressed: () {
              if (_activeEmergencyId != null) {
                // If the staff taps the notification icon and an emergency is active, show the dialog again
                _showAlert(context, _activeEmergencyId!);
              } else {
                print("Notifications opened");
              }
            },
          ),
          //--- ACCOUNT ICON BUTTON ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GestureDetector(
              onTap: () {
                // 🛑 INTEGRATING AccountMenu.show with dynamic data
                AccountMenu.show(
                  context,
                  email: userProvider.userEmail ?? 'N/A',
                  userId: userProvider.userCustomId ?? FALLBACK_STAFF_ID,
                  role: userProvider.userRole ?? 'Staff', // Use a default role if null
                );
              },
              child: CircleAvatar(
                backgroundColor: primaryNavy.withOpacity(0.1),
                child: Icon(Icons.person_rounded, color: primaryNavy),
              ),
            ),
          ),
        ],
      ),
      // --- BODY: Use Stack to layer the Overlay over the main ScrollView ---
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🛑 Display Multi-Patient Emergency Banner
                _buildMultiPatientEmergencyBanner(),

                // ------------------------------------------------------------------
                // 🛑 PATIENT DETAILS BUTTON
                // ------------------------------------------------------------------
                _buildActionCard(
                  title: "Patient Details",
                  subtitle: "Vitals, meds, and history",
                  icon: Icons.badge_outlined,
                  color: primaryNavy,
                  onTap: () {
                    // Navigate to the PatientDetailsPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PatientDetailsPage()),
                    );
                  },
                ),

                // --- VIDEO CALL BUTTON (Placeholder) ---
                _buildActionCard(
                  title: "Receive Video Call",
                  subtitle: "Awaits signal from Robot/Patient",
                  icon: Icons.videocam_rounded,
                  color: Colors.green[700]!,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Staff listens for calls automatically. Waiting for patient initiation.')),
                    );
                  },
                ),

                // --- CALL ROBOT BUTTON ---
                _buildActionCard(
                  title: "Call Robot to Station",
                  subtitle: "Summon assistant to your location",
                  icon: Icons.smart_toy_rounded,
                  color: accentBlue,
                  onTap: () => _showConfirmation(context),
                ),

                const SizedBox(height: 30),

                // --- ROBOT STATUS SECTION ---
                _buildRobotStatusFooter(patientData),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // -------------------------------------------------------------
          // 2. RINGING OVERLAY (The call popup layer)
          // -------------------------------------------------------------
          _buildRingingOverlay(context, firebaseCallService),
        ],
      ),
    );
  }
}

// Reusable Vitals Card Widget (Kept for completeness)
class VitalsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const VitalsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: 150,
        height: 100,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}