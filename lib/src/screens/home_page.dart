import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'login.dart';

// Import your destination interfaces
import 'patient_interface.dart';
import 'staff_interface.dart';
import 'robot_interface.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Schedule the routing logic to run after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileAndNavigate();
    });
  }

  Future<void> _loadProfileAndNavigate() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // 1. Load the user's profile from Firestore
    if (!userProvider.isProfileLoaded) {
      await userProvider.loadUserProfile();
    }

    // 2. Perform the routing
    _routeToDashboard(userProvider.userRole);
  }

  void _routeToDashboard(String? role) {
    if (!mounted) return;

    // Default to LoginPage if the role cannot be determined
    Widget destination = const LoginPage();

    if (role != null) {
      // Determine the destination based on the user's role
      switch (role) {
        case 'patient':
          destination = PatientDashboard();
          break;
        case 'staff':
          destination = const StaffInterface();
          break;
        case 'robot':
          destination = RobotInterface();
          break;
      }
    }

    // Replace the current screen (Router) with the correct dashboard
    // pushAndRemoveUntil ensures the user cannot press back to get stuck on the loading page
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