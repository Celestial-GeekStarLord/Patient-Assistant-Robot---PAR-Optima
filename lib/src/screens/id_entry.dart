import 'package:flutter/material.dart';
import 'patient_interface.dart';

class IdEntryPage extends StatefulWidget {
  @override
  _IdEntryPageState createState() => _IdEntryPageState();
}

class _IdEntryPageState extends State<IdEntryPage> {
  final TextEditingController _idController = TextEditingController();

  // Theme colors
  final Color skyBlue = Color(0xFF87CEEB);
  final Color offWhite = Color(0xFFFAF9F6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: offWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.blueGrey),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Instruction Icon
            Icon(Icons.badge_outlined, size: 80, color: skyBlue),
            SizedBox(height: 24),

            // Text Instructions
            Text(
              "Identity Verification",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Please enter your assigned User ID to continue.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 40),

            // User ID Input Field
            TextField(
              controller: _idController,
              keyboardType: TextInputType.number, // Good for numeric IDs
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, letterSpacing: 4),
              decoration: InputDecoration(
                hintText: "ID-0000",
                hintStyle: TextStyle(letterSpacing: 0, fontSize: 16),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: skyBlue),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: skyBlue.withOpacity(0.5)),
                ),
              ),
            ),
            SizedBox(height: 30),

            // Proceed Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PatientDashboard()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: skyBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "PROCEED",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}