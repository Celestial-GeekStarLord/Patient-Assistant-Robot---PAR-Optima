import 'package:flutter/material.dart';
import '../widgets/vitals_card.dart';
import '../widgets/action_button.dart';
import '../services/video_service.dart';
import '../utils/colors.dart';

class PatientInterface extends StatelessWidget {
  const PatientInterface({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patient Terminal - R402")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                VitalsCard(icon: Icons.favorite, value: "75", label: "BPM", color: Colors.red),
                VitalsCard(icon: Icons.thermostat, value: "98.6", label: "Temp", color: Colors.orange),
              ],
            ),
            const Spacer(),
            ActionButton(
              label: "Video Call Doctor",
              icon: Icons.videocam,
              color: AppColors.primaryBlue,
              onTap: () => print("Doctor_Room402"),
            ),
            const SizedBox(height: 15),
            ActionButton(
              label: "EMERGENCY HELP",
              icon: Icons.warning,
              color: AppColors.emergencyRed,
              onTap: () => _showEmergencyDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => const AlertDialog(title: Text("Alert Sent"), content: Text("Help is on the way.")),
    );
  }
}