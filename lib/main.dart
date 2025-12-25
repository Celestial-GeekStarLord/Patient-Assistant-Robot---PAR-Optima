import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// --- NEW/UPDATED CORE IMPORTS ---
import 'src/services/auth_service.dart'; // The core authentication logic
import 'src/providers/user_provider.dart'; // Stores user profile and role
import 'src/screens/home_page.dart'; // The Role-Based Router
import 'src/screens/login.dart'; // The login screen (assuming renamed from login.dart)

// 🛑 Existing Imports
import 'src/screens/patient_interface.dart'; // Assuming this is now PatientInterface
import 'src/screens/robot_interface.dart';
import 'src/screens/staff_interface.dart';
import 'src/services/communication_service.dart';
import 'src/services/patient_data_service.dart';
import 'firebase_options.dart';
// Note: SharedPreferences is no longer needed for auth

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. FIREBASE INITIALIZATION
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase Initialized.");
  } catch (e) {
    debugPrint('🛑 ERROR: Firebase initialization failed. Error: $e');
  }

  // --- Initialize Services ---
  final commService = CommunicationService();
  final authService = AuthService(); // Create AuthService instance

  // 2. AGORA ENGINE INITIALIZATION
  try {
    await commService.initAgora();
    debugPrint("Agora Engine Initialized.");
  } catch (e) {
    debugPrint('🛑 ERROR: Agora initialization failed. Error: $e');
  }

  // 3. LAUNCH APPLICATION WITH PROVIDERS
  runApp(
    MultiProvider(
      providers: [
        // 1. NEW: Provide AuthService for sign-in/sign-up/state changes
        Provider<AuthService>(create: (_) => authService),

        // 2. NEW: Provide UserProvider, dependent on AuthService, to hold the role
        ChangeNotifierProvider<UserProvider>(
          create: (context) => UserProvider(authService),
        ),

        // 3. Existing: PatientDataService
        ChangeNotifierProvider<PatientDataService>(
          create: (_) => PatientDataService(),
        ),

        // 4. Existing: CommunicationService
        ChangeNotifierProvider<CommunicationService>.value(value: commService),
      ],
      child: const ParOptimaApp(), // No need for initial state parameters anymore
    ),
  );
}

class ParOptimaApp extends StatelessWidget {
  const ParOptimaApp({super.key});

  // The MaterialApp now relies on the StreamBuilder to determine the initial screen
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PAR Optima Prototype',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),

      // Home widget uses StreamBuilder to react to Firebase Auth state
      home: StreamBuilder(
        // Listen to Firebase Authentication state changes (login/logout)
        stream: Provider.of<AuthService>(context).authStateChanges,
        builder: (context, snapshot) {
          // Show a simple loading screen while the connection is established
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          // If there is an authenticated user (logged in)
          if (snapshot.hasData && snapshot.data != null) {
            // User is logged in. Send them to the router (HomePage) to fetch their role
            // and navigate to the correct dashboard.
            return const HomePage();
          }

          // If no user is logged in
          return const LoginPage();
        },
      ),
    );
  }
}