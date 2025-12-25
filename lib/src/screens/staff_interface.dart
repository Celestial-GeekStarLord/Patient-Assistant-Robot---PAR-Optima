import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/patient_data_service.dart';
import '../services/communication_service.dart';
import 'video_call_screen.dart';
import 'patient_details_page.dart'; // Create this file next
import 'account.dart';

class StaffInterface extends StatelessWidget {
  const StaffInterface({super.key});

  // Modern Color Palette
  final Color primaryNavy = const Color(0xFF0D47A1);
  final Color accentBlue = const Color(0xFF1976D2);
  final Color bgGrey = const Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final patientData = Provider.of<PatientDataService>(context);

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text('STAFF HUB',
            style: TextStyle(color: primaryNavy, fontWeight: FontWeight.w900, letterSpacing: 1)),
        centerTitle: false,
        actions: [
          //--- NOTIFICATION BUTTON ---
          IconButton(
            icon: Badge(
              label: Text('2'), // Example badge
              child: Icon(Icons.notifications_none_rounded, color: primaryNavy),
            ),
            onPressed: () => print("Notifications opened"),
          ),
         //--- ACCOUNT ICON BUTTON ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GestureDetector(
              onTap: () {
                AccountMenu.show(
                    context,
                    email: "staff@hospital.com",
                    userId: "STF-9921"
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

            // --- VIDEO CALL BUTTON ---
            _buildActionCard(
              title: "Recieve Video Call",
              subtitle: "Encrypted direct line to patient",
              icon: Icons.videocam_rounded,
              color: Colors.green[700]!,
              onTap: () {
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

  void _showAccountMenu(BuildContext context) {
    // We already discussed the Modal Bottom Sheet, you can trigger it here
  }
}