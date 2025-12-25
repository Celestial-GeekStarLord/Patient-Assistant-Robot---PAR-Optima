// lib/src/screens/staff_interface.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/patient_data_service.dart';
import '../services/communication_service.dart';
import 'video_call_screen.dart'; // We will use the same screen for both parties

class StaffInterface extends StatelessWidget {
  const StaffInterface({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the real-time data from Firebase
    final patientData = Provider.of<PatientDataService>(context);

    // Get the Communication Service for the video call (to initiate it)
    final commService = Provider.of<CommunicationService>(context);

    // A simple breakpoint check for responsiveness
    bool isLargeScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PAR Optima Staff Dashboard'), // Renamed title
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // TODO: Implement Logout (Clear SharedPreferences 'isLoggedIn')
              Navigator.pop(context); // Simple pop for now
            },
          ),
        ],
      ),
      // Use a Row for the side-by-side layout on large screens
      body: Row(
        children: [
          // Sidebar (Visible only on large screens)
          if (isLargeScreen) const StaffSidebar(), // Renamed Sidebar
          // Main Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Patient Status: John Doe (Room 402)',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),

                  // Row 1: Vitals and Call Button
                  _buildStatusRow(context, patientData, commService),

                  const SizedBox(height: 30),

                  // Row 2: Robot Command and Meds Update
                  _buildCommandRow(context, patientData),

                  const SizedBox(height: 30),

                  // Robot Status Card
                  _buildRobotStatusCard(patientData),

                  const SizedBox(height: 30),

                  // Emergency Alert Card
                  _buildEmergencyAlertCard(context, patientData),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // New widget for the Emergency Alert
  Widget _buildEmergencyAlertCard(
    BuildContext context,
    PatientDataService patientData,
  ) {
    if (!patientData.emergencyPending) {
      return Container(); // Hide if no emergency
    }

    return Card(
      color: Colors.red[100],
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.red, size: 40),
                const SizedBox(width: 15),
                Text(
                  'EMERGENCY ALERT PENDING! Patient called for help.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Resolve Alert'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
              onPressed: () {
                // Set emergency status back to false in Firebase
                patientData.setEmergency(false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Emergency alert resolved.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(
    BuildContext context,
    PatientDataService patientData,
    CommunicationService commService,
  ) {
    return Wrap(
      // Use Wrap for automatic wrapping on small screens
      spacing: 20,
      runSpacing: 20,
      children: [
        // Vitals Display
        VitalsCard(
          title: 'Heart Rate',
          value: '${patientData.heartRate} BPM',
          icon: Icons.favorite,
          color: Colors.red,
        ),
        VitalsCard(
          title: 'Temperature',
          value: '${patientData.temperature}°F',
          icon: Icons.thermostat,
          color: Colors.orange,
        ),
        VitalsCard(
          title: 'Oxygen Sat.',
          value: '${patientData.oxygenSat}%',
          icon: Icons.opacity,
          color: Colors.blue,
        ),

        // Video Call Button
        Container(
          width: 200,
          height: 100,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.video_call, size: 40),
            label: const Text(
              'Start Video Call',
              style: TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size.fromHeight(100),
            ),
            onPressed: () {
              // Staff joins the call on the same channel as the patient
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VideoCallScreen(
                    channelName: "Room402_Doctor",
                    isHost: true, // Indicates this side is the staff/admin
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCommandRow(
    BuildContext context,
    PatientDataService patientData,
  ) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        // Robot Dispatch Button
        Container(
          width: 200,
          height: 100,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.send_time_extension, size: 30),
            label: const Text('Dispatch Robot', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              minimumSize: const Size.fromHeight(100),
            ),
             onPressed: () => print('YES')
               // patientData.sendRobotToRoom, // Publishes command to Firebase
          ),
        ),

        // Next Meds Update Field
        SizedBox(
          width: 250,
          child: TextField(
            onSubmitted: (value) {
              patientData.setNextMedication(value); // Updates Firebase
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Next medication time set to: $value')),
              );
            },
            decoration: InputDecoration(
              labelText: 'Set Next Meds Time',
              hintText: 'e.g., 3:30 PM',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.schedule),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRobotStatusCard(PatientDataService patientData) {
    return Card(
      color: Colors.blueGrey[50],
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Robot Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              patientData.robotStatus ?? 'Loading...',
              style: TextStyle(
                fontSize: 22,
                color: patientData.robotStatus == 'Dispatching'
                    ? Colors.red
                    : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable Vitals Card Widget
class VitalsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const VitalsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        width: 200,
        height: 100,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple placeholder for the Staff Sidebar
class StaffSidebar extends StatelessWidget {
  const StaffSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: Colors.indigo[900],
      child: ListView(
        children: const [
          DrawerHeader(
            child: Text(
              'Staff Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard, color: Colors.white),
            title: Text('Dashboard', style: TextStyle(color: Colors.white)),
          ),
          ListTile(
            leading: Icon(Icons.people, color: Colors.white70),
            title: Text(
              'Patients List',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
