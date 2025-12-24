import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// 🛑 Local Imports - Ensure these paths are correct in your project
import 'src/screens/login.dart'; // Assuming LoginPage is login_screen.dart
import 'src/screens/patient_interface.dart'; // PatientDashboard
import 'src/screens/robot_interface.dart'; // For Robot access (if needed)
import 'src/screens/staff_interface.dart'; // We should include staff/main interface
import 'src/services/communication_service.dart';
import 'src/services/patient_data_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Always call this first when using plugins
  WidgetsFlutterBinding.ensureInitialized();

  // 1. FIREBASE INITIALIZATION
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase Initialized.");
  } catch (e) {
    debugPrint(
      '🛑 ERROR: Firebase initialization failed. Did you run flutterfire configure? Error: $e',
    );
  }

  // 2. AGORA ENGINE INITIALIZATION
  // Initialize the service instance here to call the async setup method
  final commService = CommunicationService();
  try {
    // 🛑 FIX: Use the correct method name from our CommunicationService implementation
    await commService.initAgora();
    debugPrint("Agora Engine Initialized.");
  } catch (e) {
    debugPrint(
      '🛑 ERROR: Agora initialization failed. Check App ID/Permissions. Error: $e',
    );
  }

  // 3. AUTO-LOGIN CHECK
  bool isLoggedIn = false;
  String userType = 'unknown'; // Track user type for screen routing
  try {
    final prefs = await SharedPreferences.getInstance();
    isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    userType = prefs.getString('userType') ?? 'unknown';
  } catch (e) {
    debugPrint('Error accessing SharedPreferences for login check: $e');
  }

  // 4. LAUNCH APPLICATION
  runApp(
    MultiProvider(
      providers: [
        // Provides real-time data from Firebase to the UI
        ChangeNotifierProvider<PatientDataService>(
          create: (_) => PatientDataService(),
        ),
        // Provides the configured Agora service for video calls
        // Use .value since the instance was created and initialized above
        Provider<CommunicationService>.value(value: commService),
      ],
      child: ParOptimaApp(
        isLoggedIn: isLoggedIn,
        userType: userType, // Pass user type for routing
      ),
    ),
  );
}

class ParOptimaApp extends StatelessWidget {
  final bool isLoggedIn;
  final String userType;

  const ParOptimaApp({
    super.key,
    required this.isLoggedIn,
    required this.userType,
  });

  // Determines the screen to show based on login status and user type
  Widget _getInitialScreen() {
    if (!isLoggedIn) {
      // 🛑 Initial state: User must log in
      return const LoginPage();
    }

    // 🛑 If logged in, route based on user type
    switch (userType) {
      case 'patient':
        // Assuming PatientInterface holds the PatientDashboard widget
        return PatientDashboard();
      case 'staff':
        return const StaffInterface();
      case 'robot':
        return const RobotInterface();
      default:
        // Fallback or re-login if type is unknown
        return const LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PAR Optima Prototype',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch:
            Colors.indigo, // Changed to a specific color for consistency
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: _getInitialScreen(), // Use the routing logic
    );
  }
}

// 🛑 Assuming these placeholder classes exist in the imported files:
// They are needed for the routing logic.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text("Login Screen Placeholder")));
}

class StaffInterface extends StatelessWidget {
  const StaffInterface({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text("Staff Interface Placeholder")));
}

class RobotInterface extends StatelessWidget {
  const RobotInterface({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text("Robot Interface Placeholder")));
}

// void main() {
//   runApp(MaterialApp(
//     debugShowCheckedModeBanner: false,
//     home: RobotInterface(), // This tells the app to start on the Login Page
//   ));
// }
// }
