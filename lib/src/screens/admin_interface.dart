import 'package:flutter/material.dart';
import '../widgets/robot_status_badge.dart';
import '../widgets/emergency_badge.dart';

class AdminInterface extends StatelessWidget {
  const AdminInterface({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Medical Staff Portal")),
      body: Column(
        children: [
          const RobotStatusBar(location: "Ward A", battery: 92),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: const Text("Patient: John Doe (R402)"),
                  subtitle: const Text("Status: Stable"),
                  trailing: const Icon(Icons.videocam, color: Colors.blue),
                  onTap: () {},
                ),
                ListTile(
                  title: const Text("Patient: Jane Doe (R405)"),
                  subtitle: const Text("Status: Critical"),
                  trailing: const EmergencyBadge(),
                  onTap: () {},
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}