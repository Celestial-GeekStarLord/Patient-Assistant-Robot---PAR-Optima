import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'login.dart';

// Import your destination interfaces
import 'patient_interface.dart';
import 'staff_interface.dart';
import 'robot_interface.dart';
import 'call_listener_wrapper.dart'; // 🛑 NEW: Import the wrapper

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
    if (!_userProvider.isProfileLoaded) {
      await _userProvider.loadUserProfile();
    }

    // 2. Perform the routing
    _routeToDashboard(_userProvider);
  }

  // 🛑 FIX: Accept the UserProvider instance 🛑
  void _routeToDashboard(UserProvider provider) {
    if (!mounted) return;

    // Default to LoginPage if the role cannot be determined
    Widget destination = const LoginPage();
    String? role = provider.userRole; // Get the role from the passed provider
    String? customId = provider.userCustomId; // 🛑 NEW: Get the custom ID for the wrapper

    if (role != null) {
      // Determine the destination based on the user's role
      switch (role) {
        case 'patient':
        // Assuming PatientDashboard doesn't need the provider passed
          destination = PatientDashboard();
          break;
        case 'staff':
          destination = const StaffInterface();
          break;

      // 🛑 FIX APPLIED: Wrap RobotInterface in the CallListenerWrapper 🛑
        case 'robot':
          if (customId != null) {
            // Wrap the Robot Interface so it can automatically navigate to the call screen
            // once the Agora token is successfully fetched.
            destination = CallListenerWrapper(
              localUserId: customId,
              child: RobotInterface(patientUser: provider),
            );
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