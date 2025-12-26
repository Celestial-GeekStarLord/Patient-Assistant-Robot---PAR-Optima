import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class AccountMenu {
  static void show(
      BuildContext context, {
        required String email,
        required String userId,
        // 🛑 NEW: Accept the user's role
        required String role,
      }) {
    // Colors matching your Staff Hub
    final Color primaryNavy = const Color(0xFF0D47A1);

    // Capitalize the first letter of the role for display (e.g., 'staff' -> 'Staff')
    final String capitalizedRole = role.isEmpty ? 'User' : role[0].toUpperCase() + role.substring(1).toLowerCase();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Required for rounded corners
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Fits content size
          children: [
            // --- GRAB HANDLE ---
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 30),

            // --- ACCOUNT ICON (Non-Button) ---
            CircleAvatar(
              radius: 50,
              backgroundColor: primaryNavy.withOpacity(0.1),
              child: Icon(Icons.person_rounded, size: 60, color: primaryNavy),
            ),
            const SizedBox(height: 15),

            // 🛑 DYNAMIC TEXT: Show {Role} Profile
            Text(
              "$capitalizedRole Profile",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryNavy
              ),
            ),
            const SizedBox(height: 25),

            // --- USER DETAILS SECTION ---
            _buildInfoTile(Icons.alternate_email_rounded, "Email Address", email),
            const Divider(height: 1),
            // 🛑 DYNAMIC TEXT: Show {Role} ID Number
            _buildInfoTile(Icons.badge_outlined, "$capitalizedRole ID Number", userId),

            const SizedBox(height: 40),

            // --- LOGOUT BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Access the UserProvider to perform the actual logout logic
                  final userProvider = context.read<UserProvider>();

                  // 1. Execute the logout function (e.g., clear tokens, sign out Firebase auth)
                  // NOTE: Assuming UserProvider has a synchronous logout function.
                  userProvider.logout();

                  // 2. Navigate to Login and remove all previous routes
                  // NOTE: Ensure '/login' route is defined in your MaterialApp
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                label: const Text(
                  "LOGOUT",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey[400], size: 24),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }
}