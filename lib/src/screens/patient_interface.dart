import 'package:flutter/material.dart';
import '../widgets/action_button.dart';
import '../utils/colors.dart';

class PatientInterface extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: Column(
        children: [
          // Header
          _buildHeader(),
          // Main Grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: EdgeInsets.all(24),
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              children: [
                ActionButton(
                  label: "Video Call Doctor",
                  icon: Icons.medical_services,
                  color: AppColors.primaryBlue,
                  onPressed: () => print("Calling Doctor..."),
                ),
                ActionButton(
                  label: "Call Nurse",
                  icon: Icons.person,
                  color: AppColors.successGreen,
                  onPressed: () => print("Calling Nurse..."),
                ),
              ],
            ),
          ),
          // Emergency Bar
          GestureDetector(
            onTap: () => print("EMERGENCY!"),
            child: Container(
              height: 120,
              width: double.infinity,
              color: AppColors.emergencyRed,
              alignment: Alignment.center,
              child: Text("EMERGENCY ASSISTANCE",
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.black)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Room 402", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Icon(Icons.battery_charging_full, color: Colors.green),
              SizedBox(width: 10),
              Icon(Icons.wifi, color: AppColors.primaryBlue),
            ],
          )
        ],
      ),
    );
  }
}
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