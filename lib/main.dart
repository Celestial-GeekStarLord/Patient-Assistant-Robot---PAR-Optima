import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// 🛑 SCREEN IMPORTS
import 'src/screens/login.dart';
import 'src/screens/patient_interface.dart';
import 'src/screens/staff_interface.dart';
import 'src/screens/robot_interface.dart';

// SERVICE & UTILITY IMPORTS
import 'src/providers/user_provider.dart';
import 'src/services/auth_service.dart';
import 'src/services/communication_service.dart';
import 'src/services/patient_data_service.dart';

// 🛑 NEW IMPORT: The service handling Firebase signaling
import 'src/services/firebase_call_service.dart';
// Note: We still import call_service.dart if other files depend on the abstract type,
// but we no longer need the explicit import here if we use the concrete class below.
// import 'src/services/call_service.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- INITIALIZATION ---

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

  // 2. DEPENDENCY INJECTION / SERVICE INSTANCES
  final AuthService authService = AuthService();
  final CommunicationService commService = CommunicationService();
  // 🛑 NEW: Instance of the Firebase Signaling Service
  final FirebaseCallService firebaseCallService = FirebaseCallService();

  // 3. AGORA ENGINE INITIALIZATION
  try {
    await commService.initAgora();
    debugPrint("Agora Engine Initialized.");
  } catch (e) {
    debugPrint(
      '🛑 ERROR: Agora initialization failed. Check App ID/Permissions. Error: $e',
    );
  }

  // 4. AUTO-LOGIN CHECK
  bool isLoggedIn = false;
  String userType = 'unknown';
  try {
    final prefs = await SharedPreferences.getInstance();
    isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    userType = prefs.getString('userType') ?? 'unknown';
  } catch (e) {
    debugPrint('Error accessing SharedPreferences for login check: $e');
  }

  // 5. LAUNCH APPLICATION
  runApp(
    MultiProvider(
      providers: [
        // 1. Expose AuthService
        Provider<AuthService>.value(value: authService),

        // 2. UserProvider
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(authService),
        ),

        // 🛑 NEW: FirebaseCallService (Signaling)
        ChangeNotifierProvider<FirebaseCallService>.value(value: firebaseCallService),

        // 3. CommunicationService (Agora Engine)
        ChangeNotifierProvider<CommunicationService>.value(value: commService),

        // 🛑 REMOVED: The old, incorrect binding is removed. The above two services are used directly.
        // ChangeNotifierProvider<CallService>.value(value: commService),

        // 4. PatientDataService
        ChangeNotifierProxyProvider<UserProvider, PatientDataService>(
          update: (context, userProvider, previousService) {
            final channelPath = 'patients/${userProvider.userCustomId}';

            if (userProvider.userCustomId != null) {
              if (previousService != null && previousService.channelId == channelPath) {
                return previousService;
              }
              return PatientDataService(channelId: channelPath);
            }
            return PatientDataService(channelId: 'patients/placeholder');
          },
          create: (_) => PatientDataService(channelId: 'patients/initial'),
        ),
      ],
      child: ParOptimaApp(
        isLoggedIn: isLoggedIn,
        userType: userType,
      ),
    ),
  );
}

// --- APP WIDGETS ---

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
      return const LoginPage();
    }

    switch (userType) {
      case 'patient':
        return const PatientDashboard();
      case 'staff':
        return const StaffInterface();
      case 'robot':
        return const RobotInterface();
      default:
        return const LoginPage();
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