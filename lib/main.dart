import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// --- CORE SERVICES IMPORTS ---
import 'src/services/auth_service.dart';
import 'src/services/call_service.dart'; // 🛑 NEW: Import CallService
import 'src/services/communication_service.dart';
import 'src/services/patient_data_service.dart';

// --- PROVIDER & SCREEN IMPORTS ---
import 'src/providers/user_provider.dart';
import 'src/screens/home_page.dart';
import 'src/screens/login.dart';
import 'firebase_options.dart';

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
  final authService = AuthService();

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
        // 1. AuthService (Base Service)
        Provider<AuthService>(create: (_) => authService),

        // 2. UserProvider (Depends on AuthService)
        ChangeNotifierProvider<UserProvider>(
          create: (context) => UserProvider(authService),
        ),

        // 3. CommunicationService
        ChangeNotifierProvider<CommunicationService>.value(value: commService),

        // 4. CallService (🛑 FIX: Added to resolve "Provider not found" error)
        ChangeNotifierProvider<CallService>(create: (_) => CallService()),

        // 5. PatientDataService (Depends on UserProvider)
        ChangeNotifierProxyProvider<UserProvider, PatientDataService>(
          update: (context, userProvider, previousPatientService) {
            final String? channelId = userProvider.userChannelId;

            if (channelId != null) {
              if (previousPatientService != null &&
                  previousPatientService.channelId == channelId) {
                return previousPatientService;
              }
              return PatientDataService(channelId: channelId);
            } else {
              return PatientDataService(channelId: 'dummy_loading_path');
            }
          },
          create: (_) => PatientDataService(channelId: 'initial_load_path'),
        ),
      ],
      child: const ParOptimaApp(),
    ),
  );
}

class ParOptimaApp extends StatelessWidget {
  const ParOptimaApp({super.key});

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
        stream: Provider.of<AuthService>(context).authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (snapshot.hasData && snapshot.data != null) {
            // User is logged in, go to Home Page
            return const HomePage();
          }

          // User is logged out, go to Login
          return const LoginPage();
        },
      ),
    );
  }
}