import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// 🛑 FIX: ADD THE INT'L IMPORT HERE 🛑
import 'package:intl/intl.dart';

// Import the service that holds the real-time data
import '../services/patient_data_service.dart';

// --- 1. UPDATE WIDGET TO ACCEPT PARAMETERS ---
class ReportPage extends StatelessWidget {
  // These parameters are passed from PatientDetailsPage
  final String patientChannelId;
  final String patientName;

  const ReportPage({
    super.key,
    required this.patientChannelId,
    required String patientName, // Make sure this is correctly named
  }) : patientName = patientName; // Assign patientName to the final field

  @override
  Widget build(BuildContext context) {
    // Access the PatientDataService instance (listening for changes)
    final patientDataService = Provider.of<PatientDataService>(context);

    // Theme Colors
    final Color primaryNavy = const Color(0xFF0D47A1);
    final Color accentGreen = const Color(0xFF4CAF50);
    final Color warningOrange = const Color(0xFFFF9800);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // Light background
      appBar: AppBar(
        title: const Text(
          "PATIENT HEALTH REPORT",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // 🛑 FIX: The SingleChildScrollView is correctly here to handle the main body 🛑
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Patient Header ---
            _buildPatientHeader(patientName, patientChannelId, primaryNavy),
            const SizedBox(height: 30),

            // --- Vitals Section ---
            _buildSectionHeader("Real-Time Vitals", primaryNavy),
            const SizedBox(height: 10),
            _buildVitalsGrid(patientDataService, accentGreen, warningOrange),
            const SizedBox(height: 30),

            // // --- Status and Commands Section ---
            // _buildSectionHeader("Robot & State Status", primaryNavy),
            // const SizedBox(height: 10),
            // _buildStatusCard(patientDataService, primaryNavy, accentGreen, warningOrange),
          ],
        ),
      ),
    );
  }

  // --- UI Builder Methods ---

  Widget _buildPatientHeader(String name, String channelId, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          "Channel ID: $channelId",
          style: TextStyle(
            fontSize: 16,
            color: Colors.blueGrey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
        const Divider(height: 20, thickness: 1.5),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _buildVitalsGrid(PatientDataService service, Color green, Color orange) {

    // 🛑 FIX: Get the new calculated DateTime? 🛑
    final nextMedicationTime = service.nextMedicationTime;

    // 🛑 FIX: Format the DateTime? into a display string 🛑
    final nextMedicationDisplay = nextMedicationTime == null
        ? "N/A"
        : (nextMedicationTime.isBefore(DateTime.now())
        ? "OVERDUE (${DateFormat('h:mm a').format(nextMedicationTime)})" // Example formatting for overdue
        : DateFormat('h:mm a, MMM d').format(nextMedicationTime)
    );

    final Color medicationColor = nextMedicationTime != null && nextMedicationTime.isBefore(DateTime.now())
        ? Colors.red.shade700 // Overdue
        : Colors.purple.shade700; // Scheduled

    final String medicationUnit = nextMedicationTime != null && nextMedicationTime.isBefore(DateTime.now())
        ? "" // No unit for overdue message
        : "Time";


    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      // 🛑 FINAL FIX: Further reduced aspect ratio to 1.15 for guaranteed clearance 🛑
      childAspectRatio: 1.15,
      children: [
        _buildVitalsTile(
          icon: Icons.favorite_rounded,
          title: "Heart Rate (HR)",
          value: service.heartRate,
          unit: "bpm",
          color: Colors.red.shade700,
        ),
        _buildVitalsTile(
          icon: Icons.thermostat_rounded,
          title: "Temperature",
          value: service.temperature,
          unit: "°F",
          color: orange,
        ),
        _buildVitalsTile(
          icon: Icons.opacity_rounded,
          title: "Oxygen Saturation (O₂)",
          value: service.oxygenSat,
          unit: "%",
          color: green,
        ),
        _buildVitalsTile(
          icon: Icons.access_time_filled_rounded,
          title: "Next Medication",
          // 🛑 FIX: Use the calculated and formatted display value 🛑
          value: nextMedicationDisplay,
          unit: medicationUnit,
          color: medicationColor,
        ),
      ],
    );
  }


  Widget _buildVitalsTile({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required Color color,
  }) {
    // Determine font size based on content length for the Next Medication tile
    // This is a common pattern when a field might contain a long string (like the overdue message)
    final valueFontSize = (title == "Next Medication" && value.length > 10) ? 24.0 : 34.0;

    // For medication, change unit color to be less pronounced if it's a long message
    final unitColor = (title == "Next Medication" && value.length > 10) ? color.withOpacity(0.7) : color;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        // 🛑 FIX: Slightly reduce padding to give internal text more vertical space 🛑
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 8),
                // Flexible is correctly used here
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            // The large Text.rich needs the space provided by reduced padding.
            Text.rich(
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: valueFontSize, // 🛑 FIX: Dynamic font size for safety 🛑
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
                children: [
                  TextSpan(
                    text: unit,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: unitColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildStatusCard(PatientDataService service, Color primary, Color success, Color warning) {
  //   // Determine Emergency Status Appearance
  //   final isEmergency = service.emergencyPending;
  //   final emergencyColor = isEmergency ? Colors.white : Colors.grey.shade200;
  //   final emergencyBgColor = isEmergency ? Colors.red.shade600 : success;
  //
  //   // Determine Robot Status Appearance
  //   final robotStatus = service.robotStatus ?? 'N/A';
  //   final robotStatusColor = robotStatus.contains('Dispatching') ? warning : success;
  //
  //   return Card(
  //     elevation: 5,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
  //     child: Column(
  //       children: [
  //         // --- Emergency Status Row ---
  //         Container(
  //           padding: const EdgeInsets.all(15),
  //           decoration: BoxDecoration(
  //             color: emergencyBgColor,
  //             borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
  //           ),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Row(
  //                 children: [
  //                   Icon(
  //                     isEmergency ? Icons.warning_rounded : Icons.check_circle_rounded,
  //                     color: emergencyColor,
  //                     size: 28,
  //                   ),
  //                   const SizedBox(width: 10),
  //                   Text(
  //                     isEmergency ? "EMERGENCY ALERT ACTIVE" : "Patient Status Stable",
  //                     style: TextStyle(
  //                       color: emergencyColor,
  //                       fontSize: 18,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               if (isEmergency)
  //                 ElevatedButton(
  //                   onPressed: () => service.resolveEmergency(),
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: Colors.white,
  //                     foregroundColor: Colors.red.shade600,
  //                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  //                   ),
  //                   child: const Text("Resolve"),
  //                 )
  //             ],
  //           ),
  //         ),
  //
  //
  //
  //
  //       ],
  //     ),
  //   );
  // }

  Widget _buildStatusRow({required IconData icon, required String label, required String value, required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}