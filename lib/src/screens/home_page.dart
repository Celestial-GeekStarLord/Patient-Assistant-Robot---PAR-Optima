import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'login.dart';

// Import your destination interfaces
import 'patient_interface.dart';
import 'staff_interface.dart';
import 'robot_interface.dart';
// 🛑 REMOVED: import 'call_listener_wrapper.dart'; // No longer needed

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Store the UserProvider instance here, accessible after initState
  late final UserProvider _userProvider;

  @override
  void initState() {
    super.initState();
    // Initialize the provider instance here, listen: false is crucial in initState
    _userProvider = Provider.of<UserProvider>(context, listen: false);

    // Schedule the routing logic to run after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileAndNavigate();
    });
  }

  Future<void> _loadProfileAndNavigate() async {
    // 1. Load the user's profile from Firestore
    // Call loadUserProfile only if the profile hasn't been loaded yet
    if (!_userProvider.isProfileLoaded) {
      await _userProvider.loadUserProfile();
    }

    // 2. Perform the routing
    // Pass the instance that now has the loaded profile data
    _routeToDashboard(_userProvider);
  }

  // 🛑 FIX: Accept the UserProvider instance 🛑
  void _routeToDashboard(UserProvider provider) {
    if (!mounted) return;

    // Default to LoginPage if the role cannot be determined
    Widget destination = const LoginPage();
    String? role = provider.userRole;
    String? customId = provider.userCustomId; // Retain customId check for safety

    if (role != null) {
      // Determine the destination based on the user's role
      switch (role) {
        case 'patient':
        // PatientDashboard starts its own listeners internally
          destination = const PatientDashboard();
          break;

        case 'staff':
        // StaffInterface starts its call listener in its own initState
          destination = const StaffInterface();
          break;

        case 'robot':
        // RobotInterface starts its own listeners internally (if any)
          if (customId != null) {
            // 🛑 CRITICAL FIX APPLIED HERE: Direct navigation, remove CallListenerWrapper
            destination = const RobotInterface();
          } else {
            // Handle case where customId is unexpectedly null
            debugPrint("Error: Robot Custom ID is null.");
            destination = const LoginPage();
          }
          break;

        default:
          destination = const LoginPage();
          break;
      }
    }

    // Replace the current screen (Router) with the correct dashboard
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => destination),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show a simple loading screen while profile data is being fetched
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Authenticating and directing to dashboard...")
          ],
        ),
      ),
    );
  }
}