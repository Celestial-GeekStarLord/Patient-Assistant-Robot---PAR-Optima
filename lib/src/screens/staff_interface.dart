// lib/src/screens/staff_interface.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// REQUIRED CALL/LOGIC IMPORTS
import '../providers/user_provider.dart';
import '../services/firebase_call_service.dart';
import '../services/call_service.dart'; // For CallStatus enum
import '../services/communication_service.dart';
import '../services/patient_data_service.dart';

// SCREEN IMPORTS
import 'video_call_screen.dart';
import 'patient_details_page.dart'; // Ensure this file exists
import 'account.dart'; // Ensure this file exists - needed for AccountMenu

// CONVERTED TO STATEFULWIDGET (For call listening logic)
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

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure the widget and its context are fully built
    // before attempting to access Providers and start the listener.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCallListener(context);
    });
  }

  // --- LOGIC: CALL LISTENER SETUP ---
  void _startCallListener(BuildContext context) {
    try {
      // FIX: Access the Provider using listen: false inside the callback
      final firebaseCallService = Provider.of<FirebaseCallService>(context, listen: false);

      // CRITICAL: All staff devices listen on the same, common Firebase node.
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

    // 3. Navigate to the call screen
    if (mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => VideoCallScreen(
          channelName: currentCall.channelId,
          isHost: false, // Staff is joining the call
        ),
      ));
    }
  }

  /// Handles the action when the Staff declines the call.
  void _declineIncomingCall(FirebaseCallService callService) async {
    // This clears the call node for everyone, stopping the ringing.
    await callService.declineCall();
  }
  // --- END: CALL LISTENER SETUP ---


  // --- UI HELPER METHODS ---

  // --- POPUP MESSAGE ---
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

  // --- REUSABLE ACTION CARD DESIGN ---
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

  // --- EMERGENCY BANNER ---
  Widget _buildEmergencyBanner(PatientDataService patientData) {
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
          const Expanded(
            child: Text("EMERGENCY ALERT ACTIVE",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              patientData.setEmergency(false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Emergency alert resolved.')),
              );
            },
            style: TextButton.styleFrom(backgroundColor: Colors.white),
            child: const Text("RESOLVE", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  // --- ROBOT STATUS FOOTER ---
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
              Text("Robot: ${data.robotStatus ?? 'Idle'}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const Text("88% (Battery)", style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  // --- RINGING OVERLAY (Shows when firebaseCallService.status is 'ringing') ---
  Widget _buildRingingOverlay(BuildContext context, FirebaseCallService callService) {
    // This is the core logic that makes the popup appear
    if (callService.status != CallStatus.ringing) {
      return const SizedBox.shrink();
    }

    final callerName = callService.currentCall?.callerName ?? 'Patient/Robot';

    return Positioned.fill(
      child: Container(
        color: Colors.black54, // Dark transparent background
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
    final firebaseCallService = context.watch<FirebaseCallService>(); // Watch for ringing status

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
            onPressed: () => print("Notifications opened"),
          ),
          //--- ACCOUNT ICON BUTTON ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GestureDetector(
              onTap: () {
                // Assuming AccountMenu.show is available via the account.dart import
                // AccountMenu.show(context);
                print("Showing Account Menu");
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
                if (patientData.emergencyPending) _buildEmergencyBanner(patientData),

                // --- PATIENT SELECTOR / DETAILS BUTTON ---
                _buildActionCard(
                  title: "Patient Details (Room 402)",
                  subtitle: "Vitals, meds, and history",
                  icon: Icons.badge_outlined,
                  color: primaryNavy,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PatientDetailsPage()),
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

                // --- VITALS SNAPSHOT SECTION ---
                const Text('Current Vitals Snapshot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    VitalsCard(
                      title: 'Heart Rate',
                      value: '${patientData.heartRate} BPM',
                      icon: Icons.favorite,
                      color: redAlert,
                    ),
                    VitalsCard(
                      title: 'Temperature',
                      value: '${patientData.temperature}°F',
                      icon: Icons.thermostat,
                      color: Colors.orange,
                    ),
                    VitalsCard(
                      title: 'Oxygen Sat.',
                      value: '${patientData.oxygenSat}%',
                      icon: Icons.opacity,
                      color: accentBlue,
                    ),
                  ],
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

// Reusable Vitals Card Widget
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