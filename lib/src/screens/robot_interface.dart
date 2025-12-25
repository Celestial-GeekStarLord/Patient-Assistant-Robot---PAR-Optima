// lib/src/screens/robot_interface.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// REQUIRED IMPORTS
import '../providers/user_provider.dart';
import '../services/communication_service.dart';
// 🛑 NEW IMPORT: Import the Firebase Signaling Service
import '../services/firebase_call_service.dart';
import 'video_call_screen.dart'; // <--- ASSUMED PATH TO THE VIDEO CALL SCREEN

class RobotInterface extends StatelessWidget {
  const RobotInterface({
    super.key,
  });

  // Premium Color Palette
  final Color skyBlue = const Color(0xFF87CEEB);
  final Color electricBlue = const Color(0xFF00D2FF);
  final Color softGrey = const Color(0xFFF4F7F9);
  final Color emergencyRed = const Color(0xFFFF5252);
  final Color staffGreen = const Color(0xFF4CAF50);

  // 🛑 CRITICAL FIX: Define the COMMON STAFF ID
  // This must match the constant used in staff_interface.dart
  static const String COMMON_STAFF_LISTEN_ID = 'staff_group_station';

  // --- POPUP MESSAGE ---
  void _showConfirmation(BuildContext context, String message) {
    // Dismiss the dialog automatically after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded, color: staffGreen, size: 60),
            const SizedBox(height: 20),
            Text(message, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // --- HELPER TO BUILD THE PREMIUM GRADIENT BUTTONS (Unchanged) ---
  Widget _buildPremiumButton(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color topColor,
    required Color bottomColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 110,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          elevation: 6,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [topColor, bottomColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(icon, size: 45, color: Colors.white),
                const SizedBox(width: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                  ],
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.5), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final commService = context.read<CommunicationService>();
    // 🛑 NEW: Read the Firebase Signaling Service
    final firebaseCallService = context.read<FirebaseCallService>();

    // Get the required data from the provider
    final patientId = userProvider.userCustomId ?? 'robot_default';
    final patientName = userProvider.userName ?? 'Robot Patient';
    final userRole = userProvider.userRole?.toUpperCase() ?? 'N/A';

    // UID for Agora needs to be an integer (using the hashCode is a common way)
    final int userUid = patientId.hashCode;

    // 🛑 CRITICAL FIX: The target ID is now the common group ID.
    const String staffId = COMMON_STAFF_LISTEN_ID;
    const String staffName = 'Nurse Station';

    // --- NAVIGATION HELPER ---
    // Function to handle the call logic and navigation
    void startVideoCall(String channelName) async {

      // 1. 🛑 USE FirebaseCallService to send the 'ringing' signal to the COMMON ID 🛑
      final bool callInitiated = await firebaseCallService.makeCall(
        caller: userProvider,
        receiverId: staffId, // <-- This is now 'staff_group_station'
        receiverName: staffName,
      );

      if (callInitiated) {
        // 2. Patient/Robot immediately joins the channel to wait for Staff acceptance
        await commService.joinCall(
          channelName: channelName,
          userUid: userUid,
        );

        // 3. Navigate to the VideoCallScreen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              channelName: channelName,
              isHost: true, // Robot/Patient is the one initiating/hosting the channel in this context
            ),
          ),
        );
      } else {
        _showConfirmation(context, "Error initiating call signal.");
      }
    }

    return Scaffold(
      backgroundColor: softGrey,
      body: CustomScrollView(
        slivers: [
          // --- STICKY APP BAR ---
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: skyBlue,
            flexibleSpace: FlexibleSpaceBar(
              // Display the current user ID for debugging/context
              title: Text(
                "ROBOT CONTROL CENTER",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
              centerTitle: true,
            ),
          ),

          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // --- 1. CALL STAFF (Premium Gradient Style) ---
                  _buildPremiumButton(
                    context,
                    title: "CALL MEDICAL STAFF",
                    subtitle: "Connect to the nursing station",
                    icon: Icons.person_add_alt_1_rounded,
                    topColor: const Color(0xFF66BB6A),
                    bottomColor: const Color(0xFF43A047),
                    // 🛑 ACTION: Use the new signaling logic
                    onTap: () => startVideoCall('staff_channel'),
                  ),

                  const SizedBox(height: 20),

                  // --- 2. DISPATCH ROBOT (Premium Gradient Style) ---
                  _buildPremiumButton(
                    context,
                    title: "DISPATCH ROBOT",
                    subtitle: "Return robot to home station",
                    icon: Icons.rocket_launch_rounded,
                    topColor: const Color(0xFF42A5F5),
                    bottomColor: const Color(0xFF1E88E5),
                    // ACTION: Placeholder for a robot dispatch/movement function
                    onTap: () => _showConfirmation(context, "Robot Dispatched"),
                  ),

                  const SizedBox(height: 20),

                  // --- 3. EMERGENCY BUTTON (The "Main Event") ---
                  SizedBox(
                    width: double.infinity,
                    height: 120,
                    child: ElevatedButton(
                      // 🛑 ACTION: Use the new signaling logic
                      onPressed: () => startVideoCall('emergency_channel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: emergencyRed,
                        foregroundColor: Colors.white,
                        elevation: 12,
                        shadowColor: emergencyRed.withOpacity(0.6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated-looking pulse icon
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.emergency_share_rounded, size: 40),
                          ),
                          const SizedBox(width: 20),
                          const Text("EMERGENCY", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- 4. PATIENT STATUS (Unchanged) ---
                  // Additional placeholder for status or information

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}