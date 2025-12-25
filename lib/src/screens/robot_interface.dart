import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- SERVICE/PROVIDER IMPORTS ---
import '../services/call_service.dart';
import '../providers/user_provider.dart';

class RobotInterface extends StatelessWidget {
  // Premium Color Palette
  final Color skyBlue = const Color(0xFF87CEEB);
  final Color softGrey = const Color(0xFFF4F7F9);
  final Color emergencyRed = const Color(0xFFFF5252);
  final Color staffGreen = const Color(0xFF4CAF50); // Green for success
  final Color infoBlue = const Color(0xFF2196F3); // Blue for loading/info
  final Color failureRed = const Color(0xFFD32F2F); // Deeper red for failure

  // We need to receive the Patient's UserProvider instance when navigating here
  final UserProvider patientUser;

  const RobotInterface({super.key, required this.patientUser});

  // --- HELPER TO BUILD THE PREMIUM GRADIENT BUTTONS ---
  // 🛑 RE-INSERTED: This function logic was missing and caused errors 🛑
  Widget _buildPremiumButton(
      BuildContext context, {
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

  // --- POPUP MESSAGE (Modified to handle icons dynamically) ---
  void _showStatusDialog(BuildContext context, String message, {
    required IconData icon,
    required Color iconColor,
    bool showOKButton = true, // Control visibility of OK button
  }) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 60),
            const SizedBox(height: 20),
            Text(message, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
        actions: showOKButton
            ? [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: TextStyle(color: skyBlue, fontWeight: FontWeight.bold),
            ),
          ),
        ]
            : null, // No actions if showOKButton is false
      ),
    );
  }

  // Helper method for loading dialog
  void _showLoadingDialog(BuildContext context) {
    _showStatusDialog(
        context,
        "Initiating call...",
        icon: Icons.sync_rounded,
        iconColor: infoBlue,
        showOKButton: false
    );
  }

  // Helper method for failure dialog
  void _showFailureDialog(BuildContext context, String message) {
    _showStatusDialog(
        context,
        message,
        icon: Icons.error_outline_rounded,
        iconColor: failureRed,
        showOKButton: true
    );
  }


  @override
  Widget build(BuildContext context) {
    // 🛑 ACCESS: CallService and get the Staff ID
    final callService = Provider.of<CallService>(context, listen: false);
    final String staffId = patientUser.staffId ?? 'STAFF_ID_FOR_TESTING';

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
              title: const Text("ROBOT CONTROL CENTER",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              centerTitle: true,
            ),
          ),

          // 🛑 MAIN CONTENT SLIVER 🛑
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // --- 1. CALL STAFF ---
                    _buildPremiumButton(
                      context,
                      title: "CALL MEDICAL STAFF",
                      subtitle: "Connect to the nursing station",
                      icon: Icons.person_add_alt_1_rounded,
                      topColor: const Color(0xFF66BB6A),
                      bottomColor: const Color(0xFF43A047),
                      onTap: () async {
                        // 1. Show Loading Dialog
                        _showLoadingDialog(context);

                        // 2. Attempt to make the call
                        final success = await callService.makeCall(
                          caller: patientUser,
                          receiverId: staffId,
                          receiverName: "Staff/Doctor",
                        );

                        // 3. Dismiss the Loading Dialog
                        Navigator.pop(context);

                        // 4. Handle Failure
                        if (!success) {
                          _showFailureDialog(context, "Call Failed: Token or Firebase connection error.");
                        }
                        // 5. Handle Success: Navigation is handled by the CallListenerWrapper
                      },
                    ),

                    const SizedBox(height: 20),

                    // --- 2. DISPATCH ROBOT ---
                    _buildPremiumButton(
                      context,
                      title: "DISPATCH ROBOT",
                      subtitle: "Return robot to home station",
                      icon: Icons.rocket_launch_rounded,
                      topColor: const Color(0xFF42A5F5),
                      bottomColor: const Color(0xFF1E88E5),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showStatusDialog(context, "Robot Dispatched", icon: Icons.flight_land_rounded, iconColor: infoBlue); // Changed color to infoBlue
                      },
                    ),

                    const SizedBox(height: 20),

                    // --- 3. EMERGENCY BUTTON ---
                    SizedBox(
                      width: double.infinity,
                      height: 120,
                      child: ElevatedButton(
                        onPressed: () => _showStatusDialog(context, "Staff Alerted", icon: Icons.bolt_rounded, iconColor: emergencyRed),
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
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}