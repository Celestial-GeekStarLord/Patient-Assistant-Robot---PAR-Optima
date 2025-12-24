import 'package:flutter/material.dart';

class RobotStatusBar extends StatelessWidget {
  final String location;
  final int battery;

  const RobotStatusBar({super.key, required this.location, required this.battery});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.blueGrey.shade900,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Robot: $location", style: const TextStyle(color: Colors.white)),
          Row(children: [
            const Icon(Icons.battery_std, color: Colors.green, size: 16),
            Text(" $battery%", style: const TextStyle(color: Colors.white)),
          ]),
        ],
      ),
    );
  }
}