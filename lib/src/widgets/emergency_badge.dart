import 'package:flutter/material.dart';

class EmergencyBadge extends StatelessWidget {
  const EmergencyBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(5)),
      child: const Text("EMERGENCY", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}