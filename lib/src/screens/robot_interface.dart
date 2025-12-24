import 'package:flutter/material.dart';
import 'video_call_screen.dart';

class RobotInterface extends StatelessWidget {
  // Premium Color Palette
  final Color skyBlue = Color(0xFF87CEEB);// Professional Navy
  final Color electricBlue = Color(0xFF00D2FF);
  final Color softGrey = Color(0xFFF4F7F9);
  final Color emergencyRed = Color(0xFFFF5252);
  final Color staffGreen = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
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
              title: Text("ROBOT CONTROL CENTER",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              centerTitle: true,
            ),
          ),

          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  SizedBox(height: 20),

                  // --- 1. CALL STAFF (Premium Gradient Style) ---
                  _buildPremiumButton(
                    context,
                    title: "CALL MEDICAL STAFF",
                    subtitle: "Connect to the nursing station",
                    icon: Icons.person_add_alt_1_rounded,
                    topColor: Color(0xFF66BB6A),
                    bottomColor: Color(0xFF43A047),
                    onTap: (){
                      // Define the channel the robot should join
                      const String robotChannel = 'room_402'; // Use the correct channel for this robot/patient

                      // Navigate to the VideoCallScreen, providing all required parameters
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VideoCallScreen(
                            // 🛑 FIX: Provide the required channelName
                            channelName: robotChannel,
                            // 🛑 FIX: Provide the required isHost status (Robot is NOT the host/staff)
                            isHost: false,
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 20),

                  // --- 2. DISPATCH ROBOT (Premium Gradient Style) ---
                  _buildPremiumButton(
                    context,
                    title: "DISPATCH ROBOT",
                    subtitle: "Return robot to home station",
                    icon: Icons.rocket_launch_rounded,
                    topColor: Color(0xFF42A5F5),
                    bottomColor: Color(0xFF1E88E5),
                    onTap: () => _showConfirmation(context, "Robot Dispatched"),
                  ),

                  SizedBox(height: 20),

                  // --- 3. EMERGENCY BUTTON (The "Main Event") ---
                  SizedBox(
                    width: double.infinity,
                    height: 120,
                    child: ElevatedButton(
                      onPressed: () => _showConfirmation(context, "Staff Alerted"),
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
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.emergency_share_rounded, size: 40),
                          ),
                          SizedBox(width: 20),
                          Text("EMERGENCY", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER TO BUILD THE PREMIUM GRADIENT BUTTONS ---
  Widget _buildPremiumButton(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color topColor,
    required Color bottomColor,
    required VoidCallback onTap
  }) {
    return SizedBox(
      width: double.infinity,
      height: 110,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero, // Remove padding to let gradient fill
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
                SizedBox(width: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                  ],
                ),
                Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.5), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- POPUP MESSAGE ---
  void _showConfirmation(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded, color: staffGreen, size: 60),
            SizedBox(height: 20),
            Text(message, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}