import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// 🛑 Local Imports - Ensure these paths are correct in your project
import 'src/screens/login.dart';
import 'src/screens/patient_interface.dart';
import 'src/screens/robot_interface.dart';
import 'src/screens/staff_interface.dart';
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
  final commService = CommunicationService();
  try {
    await commService.initAgora();
    debugPrint("Agora Engine Initialized.");
  } catch (e) {
    debugPrint(
      '🛑 ERROR: Agora initialization failed. Check App ID/Permissions. Error: $e',
    );
  }

  // 3. AUTO-LOGIN CHECK
  bool isLoggedIn = false;
  String userType = 'unknown';
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
        // 🛑 FIX APPLIED: Changed to ChangeNotifierProvider.value to handle
        // the CommunicationService's notifyListeners() calls correctly.
        ChangeNotifierProvider<CommunicationService>.value(value: commService),
      ],
      child: ParOptimaApp(
        isLoggedIn: isLoggedIn,
        userType: userType,
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
      return StaffInterface();
    }

    // 🛑 If logged in, route based on user type
    switch (userType) {
      case 'patient':
      // 🛑 FIX APPLIED: Removed 'const' keyword here as PatientDashboard is non-const.
        return PatientDashboard();
      case 'staff':
        return const StaffInterface();
      case 'robot':
        return RobotInterface();
      default:
      // Fallback or re-login if type is unknown
        return LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PAR Optima Prototype',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: _getInitialScreen(),
    );
  }
}

// 🛑 IMPORTANT: These placeholder classes should be REMOVED from main.dart
// once you create the actual files they import from (e.g., login.dart).
// I will remove them here, assuming your actual imports (like 'src/screens/login.dart')
// define them correctly.

// void main() {
//   runApp(MaterialApp(
//     debugShowCheckedModeBanner: false,
//     home: RobotInterface(), // This tells the app to start on the Login Page
//   ));
// }
// }
