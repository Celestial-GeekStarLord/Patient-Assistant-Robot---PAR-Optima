import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// 🛑 SCREEN IMPORTS
import 'src/screens/login.dart'; // Assuming LoginPage is defined here
import 'src/screens/patient_interface.dart'; // Assuming PatientDashboard is defined here
import 'src/screens/staff_interface.dart';
import 'src/screens/robot_interface.dart';

// SERVICE & UTILITY IMPORTS
import 'src/providers/user_provider.dart';
import 'src/services/auth_service.dart';
import 'src/services/communication_service.dart';
import 'src/services/patient_data_service.dart';

// 🛑 NEW IMPORT: The service handling Firebase signaling
import 'src/services/firebase_call_service.dart';
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
  final FirebaseCallService firebaseCallService = FirebaseCallService();
  // 🛑 FIX STEP 1: Instantiate UserProvider early
  final UserProvider userProvider = UserProvider(authService);


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
  String? lastUid; // Used by AuthService/UserProvider, but good to know we checked for it
  try {
    final prefs = await SharedPreferences.getInstance();
    isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    userType = prefs.getString('userType') ?? 'unknown';
    lastUid = prefs.getString('lastUid');
  } catch (e) {
    debugPrint('Error accessing SharedPreferences for login check: $e');
  }

  // 🛑 CRITICAL FIX STEP 2: LOAD USER PROFILE SYNCHRONOUSLY IF LOGGED IN
  if (isLoggedIn && lastUid != null) {
    // Wait for the profile to load. This ensures userCustomId is set in the provider
    // BEFORE the MultiProvider starts initializing services that depend on it.
    await userProvider.loadUserProfile();

    // Update the userType based on the fresh data loaded from Firestore
    if(userProvider.userRole != null) {
      userType = userProvider.userRole!;
    } else {
      // If profile loading failed (e.g., deleted Firestore record), reset login status
      isLoggedIn = false;
      debugPrint('Auto-login failed: Profile not found in Firestore. Resetting login status.');
    }
  }


  // 5. LAUNCH APPLICATION
  runApp(
    MultiProvider(
      providers: [
        // 1. Expose AuthService
        Provider<AuthService>.value(value: authService),

        // 2. UserProvider (Use the pre-initialized instance)
        ChangeNotifierProvider<UserProvider>.value(value: userProvider),

        // 🛑 NEW: FirebaseCallService (Signaling)
        ChangeNotifierProvider<FirebaseCallService>.value(value: firebaseCallService),

        // 3. CommunicationService (Agora Engine)
        ChangeNotifierProvider<CommunicationService>.value(value: commService),

        // 4. PatientDataService
        ChangeNotifierProxyProvider<UserProvider, PatientDataService>(
          // The update logic now has access to the correct userCustomId from the start
          update: (context, userProvider, previousService) {
            final customId = userProvider.userCustomId;

            if (customId != null) {
              final channelPath = 'patients/$customId';

              if (previousService != null && previousService.channelId == channelPath) {
                // If the path hasn't changed, reuse the existing service instance
                return previousService;
              }
              // Initialize or re-initialize with the correct patient path
              return PatientDataService(channelId: channelPath);
            }
            // Fallback for when the profile hasn't loaded or user is logging out
            return previousService ?? PatientDataService(channelId: 'patients/placeholder');
          },
          // Initial creation is placeholder
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
    // Note: The isLoggedIn and userType variables are now reliable because
    // the userProvider.loadUserProfile() completed and updated them.
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
        // Define other global styles here
      ),

      // 🛑 IMPLEMENTING ROUTES FOR NAMED NAVIGATION
      initialRoute: '/', // Use the root route to load the initial screen logic
      routes: {
        // '/': loads the _getInitialScreen logic
        '/': (context) => _getInitialScreen(),

        // '/login': This is the target for the logout button's pushNamedAndRemoveUntil
        '/login': (context) => const LoginPage(),

        // Define other main interfaces if you navigate to them by name
        '/staff': (context) => const StaffInterface(),
        '/patient': (context) => const PatientDashboard(),
      },
      // Note: We use the 'routes' map instead of 'home' property
      // to ensure the named route '/login' is correctly registered.
    );
  }
}