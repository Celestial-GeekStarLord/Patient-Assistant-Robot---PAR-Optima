import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- UPDATED IMPORTS ---
import '../services/patient_data_service.dart';
import '../providers/user_provider.dart';
import 'report.dart'; // Ensure this is the updated ReportPage that takes parameters
import 'account.dart'; // AccountMenu class is defined here

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  // Theme Colors
  final Color skyBlue = const Color(0xFF87CEEB);
  final Color offWhite = const Color(0xFFF0F4F8);
  final Color emergencyRed = const Color(0xFFFF5252);
  final Color medOrange = const Color(0xFFFFB74D);
  final Color staffGreen = const Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    // 🛑 DATA ACCESS: Get real-time patient-specific data
    final patientDataService = Provider.of<PatientDataService>(context);

    // 🛑 DATA ACCESS: Use the UserProvider to access user details
    final userProvider = Provider.of<UserProvider>(context);

    // DYNAMIC: Accessing user data via UserProvider's getters
    final String currentPatientName = userProvider.userName ?? "Patient";
    // CRITICAL: Get the room number/channelId to pass to the robot request AND ReportPage
    final String currentChannelId = patientDataService.channelId; // Use the service's channelId for consistency
    final String currentRoomNumber = userProvider.roomNumber; // Use this for display only
    final String currentEmail = userProvider.userEmail ?? "N/A";
    final String currentCustomId = userProvider.userCustomId ?? "N/A";

    return Scaffold(
      backgroundColor: offWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. HEADER AREA ---
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🛑 DYNAMIC: Patient Name from UserProvider
                        Text(
                          currentPatientName,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // 🛑 DYNAMIC: Room ID from UserProvider (Used for display)
                        Text(
                          "Room $currentRoomNumber",
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    // Account Icon Button
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          // Pass dynamic user data including the role to the AccountMenu
                          AccountMenu.show(
                              context,
                              email: currentEmail,
                              userId: currentCustomId,
                              role: "Patient" // Explicitly define the role
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: const CircleBorder(),
                          elevation: 2,
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: skyBlue,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- 2. NEXT MEDICATION BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 90,
                child: ElevatedButton(
                  onPressed: () => debugPrint("Medication Details Clicked"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: medOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.medication_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 15),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Next Medication",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          // 🛑 DYNAMIC: Next Meds Time from PatientDataService
                          Text(
                            patientDataService.nextMedsTime,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- 3. MAIN GRID (HEALTH INFO & CALL ROBOT) ---
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: [
                    // HEALTH INFO BUTTON (View Medical History)
                    SizedBox(
                      child: ElevatedButton(
                        onPressed: () {
                          // 🛑 FIX APPLIED: Pass required parameters to ReportPage.
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReportPage(
                                patientChannelId: currentChannelId,
                                patientName: currentPatientName,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 2,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.analytics_rounded,
                              size: 50,
                              color: skyBlue,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Health Info",
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // CALL ROBOT BUTTON
                    SizedBox(
                      child: ElevatedButton(
                        onPressed: () {
                          // 🛑 ACTION: Pass the room number/channel ID to the service.
                          patientDataService.requestRobot(currentRoomNumber);

                          // Show the Pop-up confirmation
                          _showConfirmation(context, "Robot is on the way to Room $currentRoomNumber!");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 2,
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.smart_toy_rounded,
                              size: 50,
                              color: Colors.indigoAccent,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Call Robot",
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- 4. EMERGENCY BUTTON ---
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: ElevatedButton(
                    onPressed: () {
                      // 🛑 ACTION: Trigger Emergency via Firebase.
                      patientDataService.setEmergency(true);

                      _showConfirmation(context, "Staff Alerted");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: emergencyRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 5,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "EMERGENCY",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for confirmation dialogs
  void _showConfirmation(BuildContext context, String message) {
    // Colors for the dialog
    final Color staffGreen = const Color(0xFF4CAF50);
    final Color skyBlue = const Color(0xFF87CEEB);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: staffGreen,
              size: 60,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Closes the pop-up
            child: Text(
              "OK",
              style: TextStyle(color: skyBlue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}