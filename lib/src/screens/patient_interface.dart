import 'package:flutter/material.dart';
import 'report.dart';

class PatientDashboard extends StatelessWidget {
  // Theme Colors
  final Color skyBlue = Color(0xFF87CEEB);
  final Color offWhite = Color(0xFFF0F4F8);
  final Color emergencyRed = Color(0xFFFF5252);
  final Color medOrange = Color(0xFFFFB74D);
  final Color staffGreen = Color(0xFF4CAF50);

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
              // --- 1. HEADER AREA ---
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text("Alex Johnson", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        Text("Room 402", style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
                      ],
                    ),
                    // Account Icon Button (Sizedbox + Elevated)
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () => print("Account Clicked"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: CircleBorder(),
                          elevation: 2,
                        ),
                        child: Icon(Icons.person_rounded, color: skyBlue, size: 30),
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
                  onPressed: () => print("Medication Details Clicked"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: medOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.medication_rounded, size: 40, color: Colors.white),
                      SizedBox(width: 15),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Next Medication", style: TextStyle(color: Colors.white, fontSize: 14)),
                          Text("2:30 PM (In 45 mins)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 30),

              // --- 3. MAIN GRID (HEALTH INFO & CALL ROBOT) ---
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: [
                    // HEALTH INFO BUTTON
                    SizedBox(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ReportPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 2,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.analytics_rounded, size: 50, color: skyBlue),
                            SizedBox(height: 10),
                            Text("Health Info", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),

                    // CALL ROBOT BUTTON
                    // CALL ROBOT BUTTON
                    SizedBox(
                      child: ElevatedButton(
                        onPressed: () {
                          // 1. TRIGGER THE POP-UP
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: Icon(Icons.smart_toy_rounded, size: 50, color: skyBlue),
                                content: const Text(
                                  "Robot is on the way!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context), // Closes the pop-up
                                    child: Text("OK", style: TextStyle(color: skyBlue, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 2,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.smart_toy_rounded, size: 50, color: Colors.indigoAccent),
                            const SizedBox(height: 10),
                            const Text("Call Robot", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
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
                    onPressed: () => _showConfirmation(context, "Staff Alerted"),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: emergencyRed,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 5,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_rounded, color: Colors.white, size: 30),
                        SizedBox(width: 10),
                        Text(
                          "EMERGENCY",
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
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