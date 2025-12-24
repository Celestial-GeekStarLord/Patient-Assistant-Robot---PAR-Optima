import 'package:flutter/material.dart';

class PatientDashboard extends StatelessWidget {
  final Color skyBlue = Color(0xFF87CEEB);
  final Color offWhite = Color(0xFFF0F4F8);
  final Color emergencyRed = Color(0xFFFF5252);
  final Color medOrange = Color(0xFFFFB74D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: offWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. HEADER (Account Icon as ElevatedButton) ---
              _buildHeader(context),

              SizedBox(height: 25),

              // --- 2. NEXT MEDICATION (Big Horizontal ElevatedButton) ---
              _buildMedicationButton(context),

              SizedBox(height: 25),

              // --- 3. VITALS STRIP (Informational) ---
              _buildVitalsStrip(),

              SizedBox(height: 30),

              // --- 4. MAIN GRID (Health Info & Call Robot ElevatedButtons) ---
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: [
                    _buildGridButton(
                      context,
                      "Health Info",
                      Icons.analytics_rounded,
                      skyBlue,
                          () => print("Navigating to Health Info..."),
                    ),
                    _buildGridButton(
                      context,
                      "Call Robot",
                      Icons.smart_toy_rounded,
                      Colors.indigoAccent,
                          () => print("Navigating to Robot Control..."),
                    ),
                  ],
                ),
              ),

              // --- 5. EMERGENCY BUTTON (Red ElevatedButton) ---
              _buildEmergencyButton(context),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // HEADER WITH ACCOUNT ICON BUTTON
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Room 402", style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
              const Text("Alex Johnson", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
          // Account Icon Button
          ElevatedButton(
            onPressed: () => print("Account clicked"),
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
              backgroundColor: Colors.white,
              foregroundColor: skyBlue, // Ripple color
              elevation: 2,
            ),
            child: Icon(Icons.person_rounded, size: 30),
          ),
        ],
      ),
    );
  }

  // MEDICATION BUTTON
  Widget _buildMedicationButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 90,
      child: ElevatedButton(
        onPressed: () => print("Medication clicked"),
        style: ElevatedButton.styleFrom(
          backgroundColor: medOrange,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: medOrange.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Row(
          children: [
            const Icon(Icons.medication_rounded, size: 40),
            const SizedBox(width: 15),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Next Medication", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
                Text("2:30 PM (In 45 mins)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // GRID BUTTON HELPER
  Widget _buildGridButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color, // This colors the ripple and text/icon when pressed
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: color),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  // EMERGENCY BUTTON
  Widget _buildEmergencyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ElevatedButton.icon(
        onPressed: () => print("EMERGENCY!"),
        icon: const Icon(Icons.campaign_rounded, size: 32, color: Colors.white),
        label: const Text("HELP / EMERGENCY", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: emergencyRed,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: emergencyRed.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }

  // VITALS DATA (Keep as Container since it's just display data)
  Widget _buildVitalsStrip() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSmallVital(Icons.favorite, "72 bpm", Colors.redAccent),
        _buildSmallVital(Icons.thermostat, "98.6 °F", Colors.orange),
        _buildSmallVital(Icons.water_drop, "98%", Colors.blue),
      ],
    );
  }

  Widget _buildSmallVital(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}