import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import '../providers/user_provider.dart';

class RoomSelectionPage extends StatelessWidget {


  final Color primaryNavy = const Color(0xFF0D47A1);
  final Color headerBlue = Colors.blue;

  // Added FirebaseDatabase instance
  final DatabaseReference _rtdb = FirebaseDatabase.instance.ref();

  // --- NEW: Command mapping function ---
  String? _getRoomCommand(String roomNumber) {
    switch (roomNumber) {
      case '401':
        return 'w';
      case '402':
        return 'a';
      case '403':
        return 's';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("SELECT DESTINATION",
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: Colors.white,
        foregroundColor: primaryNavy,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Dispatch Robot",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Select a room to send the assistance robot.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Grid of Room Buttons
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildRoomButton(context, "401"),
                  _buildRoomButton(context, "402"),
                  _buildRoomButton(context, "403"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomButton(BuildContext context, String roomNumber) {
    return InkWell(
      onTap: () {
        _showDispatchConfirmation(context, roomNumber);
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [headerBlue, primaryNavy],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.meeting_room, color: Colors.white, size: 40),
              const SizedBox(height: 10),
              Text(
                "ROOM",
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
              ),
              Text(
                roomNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDispatchConfirmation(BuildContext context, String room) {
    // 1. Map the room to the command character (w, a, or s)
    final command = _getRoomCommand(room);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Dispatch"),
        content: Text("Send PAR Robot to Room $room (Command: $command)?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryNavy),
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              if (command == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: Room $room does not have a defined command.")),
                );
                return;
              }

              try {
                // 2. Define the RTDB path as 'cmd'
                final commandPath = 'cmd/data';

                // 3. Send the command string directly to the 'cmd' path
                // The robot listener will pick up the 'w', 'a', or 's' character.
                await _rtdb.child(commandPath).set(command);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Robot command '$command' sent for Room $room.")),
                );
              } catch (e) {
                debugPrint("Error dispatching robot command: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Failed to send robot command: ${e.toString()}")),
                );
              }
            },
            child: const Text("DISPATCH", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}