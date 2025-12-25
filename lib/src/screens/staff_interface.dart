import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- IMPORTS ---
import '../services/patient_data_service.dart';
import '../services/call_service.dart'; // 🛑 NEW: Required for calling
import '../services/communication_service.dart';
import '../providers/user_provider.dart'; // 🛑 NEW: To get Staff ID
import 'video_call_screen.dart';
import 'patient_details_page.dart';
import 'account.dart';

// 🛑 Changed to StatefulWidget to handle Call Listening
class StaffInterface extends StatefulWidget {
  const StaffInterface({super.key});

  @override
  State<StaffInterface> createState() => _StaffInterfaceState();
}

class _StaffInterfaceState extends State<StaffInterface> {
  // Modern Color Palette
  final Color primaryNavy = const Color(0xFF0D47A1);
  final Color accentBlue = const Color(0xFF1976D2);
  final Color bgGrey = const Color(0xFFF8FAFC);

  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    // Start listening for calls as soon as the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListeningForCalls();
    });
  }

  // 🛑 FIX: Added mounted check and improved retry logic for listener initialization.
  void _startListeningForCalls() {
    if (!mounted || _isListening) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final callService = Provider.of<CallService>(context, listen: false);

    // 🛑 LOGIC: Listen for calls sent to this Staff Member's ID
    final String? myStaffId = userProvider.userCustomId;

    if (myStaffId != null && myStaffId.isNotEmpty) {
      debugPrint("🎧 Staff Interface: LISTENER STARTED for calls to $myStaffId");
      callService.startListeningForCalls(myStaffId);

      // Use Future.microtask to update state after the current build cycle
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _isListening = true;
          });
        }
      });

    } else {
      debugPrint("⚠️ Staff Interface: ID ($myStaffId) missing/invalid. Retrying listener in 1 second.");
      // Retry if ID is not immediately available (e.g., if UserProvider is still loading)
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _startListeningForCalls();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientData = Provider.of<PatientDataService>(context);

    // 🛑 WRAPPER: Consumer watches for incoming calls
    return Consumer<CallService>(
      builder: (context, callService, child) {

        // 🚨 FIX: Guard navigation to prevent repeated pushes.
        if (callService.currentCall != null &&
            callService.currentCall!.status == 'ringing') {

          final bool isStaffInterfaceRoute = ModalRoute.of(context)?.isCurrent ?? false;
          // Check if the route directly above is NOT the IncomingCallScreen
          final isIncomingCallScreenVisible = ModalRoute.of(context)?.settings.name == 'IncomingCallScreen';

          if (isStaffInterfaceRoute && !isIncomingCallScreenVisible) {
            Future.microtask(() {
              // Push the IncomingCallScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  // Use a distinct name for better route stack checking
                  settings: const RouteSettings(name: 'IncomingCallScreen'),
                  builder: (context) => IncomingCallScreen(
                    callService: callService,
                    callerName: callService.currentCall!.callerName,
                  ),
                ),
              );
            });
          }
        }

        return Scaffold(
          backgroundColor: bgGrey,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            title: Text(
                'STAFF HUB ${_isListening ? "(Online)" : "(Offline)"}',
                style: TextStyle(color: primaryNavy, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 18)
            ),
            centerTitle: false,
            actions: [
              //--- NOTIFICATION BUTTON ---
              IconButton(
                icon: Badge(
                  label: const Text('2'),
                  child: Icon(Icons.notifications_none_rounded, color: primaryNavy),
                ),
                onPressed: () => debugPrint("Notifications opened"),
              ),
              //--- ACCOUNT ICON BUTTON ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GestureDetector(
                  onTap: () {
                    // Accessing UserProvider again for dynamic data
                    final userProvider = Provider.of<UserProvider>(context, listen: false);
                    AccountMenu.show(
                        context,
                        email: userProvider.userEmail ?? "N/A",
                        userId: userProvider.userCustomId ?? "N/A"
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                if (patientData.emergencyPending) _buildEmergencyBanner(patientData),

                // --- PATIENT SELECTOR / DETAILS BUTTON ---
                _buildActionCard(
                  title: "Patient Details",
                  subtitle: "See patient details",
                  icon: Icons.badge_outlined,
                  color: primaryNavy,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PatientDetailsPage()),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // --- MANUAL VIDEO CALL BUTTON (Fallback) ---
                _buildActionCard(
                  title: "Join Active Call",
                  subtitle: "Manually join Room 402",
                  icon: Icons.videocam_rounded,
                  color: Colors.green[700]!,
                  onTap: () {
                    // Manual override for testing
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VideoCallScreen(
                          channelName: "room_402",
                          isHost: true,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // --- CALL ROBOT BUTTON ---
                _buildActionCard(
                  title: "Call Robot",
                  subtitle: "Summon assistant to your location",
                  icon: Icons.smart_toy_rounded,
                  color: accentBlue,
                  onTap: () => _showConfirmation(context),
                ),

                const SizedBox(height: 30),

                // --- ROBOT STATUS SECTION ---
                _buildRobotStatusFooter(patientData),
              ],
            ),
          ),
        );
      },
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
    return SizedBox(
      width: double.infinity,
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

  Widget _buildEmergencyBanner(PatientDataService patientData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[600],
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
            onPressed: () => patientData.setEmergency(false),
            style: TextButton.styleFrom(backgroundColor: Colors.white),
            child: const Text("RESOLVE", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

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
          const Text("88%", style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 🛑 INCOMING CALL SCREEN CLASS (Added Here)
// ---------------------------------------------------------
class IncomingCallScreen extends StatelessWidget {
  final CallService callService;
  final String callerName;

  const IncomingCallScreen({
    super.key,
    required this.callService,
    required this.callerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Caller Info
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 30),
            const Text(
              "INCOMING CALL",
              style: TextStyle(color: Colors.white54, letterSpacing: 2.0),
            ),
            const SizedBox(height: 10),
            Text(
              callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 80),

            // 2. Action Buttons (Accept / Decline)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // DECLINE BUTTON
                Column(
                  children: [
                    FloatingActionButton.large(
                      heroTag: "btnDecline", // Unique tag for hero animation
                      onPressed: () {
                        callService.endCall();
                        Navigator.pop(context);
                      },
                      backgroundColor: Colors.redAccent,
                      child: const Icon(Icons.call_end),
                    ),
                    const SizedBox(height: 10),
                    const Text("Decline", style: TextStyle(color: Colors.white)),
                  ],
                ),

                // ACCEPT BUTTON
                Column(
                  children: [
                    FloatingActionButton.large(
                      heroTag: "btnAccept", // Unique tag for hero animation
                      onPressed: () async {
                        // 1. Update status
                        await callService.acceptCall();

                        // 2. Get Channel ID (defaulting to room_402 if missing)
                        final channelId = callService.currentCall?.channelId ?? "room_402";

                        if (context.mounted) {
                          // 3. Navigate to Video Call
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoCallScreen(
                                channelName: channelId,
                                isHost: true,
                              ),
                            ),
                          );
                        }
                      },
                      backgroundColor: Colors.greenAccent,
                      child: const Icon(Icons.call),
                    ),
                    const SizedBox(height: 10),
                    const Text("Accept", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}