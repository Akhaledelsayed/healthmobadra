import 'package:flutter/material.dart';
import 'dart:async'; // Required for Future.delayed simulation
import 'Authentication Screen (Login/Register).dart';
import 'Onboarding Screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthmobadra/Home%20Dashboard%20Screen.dart';
import 'package:healthmobadra/Profile%20Screen.dart';
import 'package:healthmobadra/api_service.dart';

// --- Simulation: In a real app, use shared_preferences or a state management package ---
class AppConfig {
  // Keep runtime auth flag; onboarding persistence moved to SharedPreferences
  static bool isAuthenticated = false;       // Simulated authentication state
}
// -----------------------------------------------------------------------------------

void main() {
  runApp(const HealthApp());
}

class HealthApp extends StatelessWidget {
  const HealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Trackedddr',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      // Use the AuthGate to determine the starting screen
      home: const SplashCheckScreen(), 
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

// ----------------------------------------------------
// The Auth Gate / Splash Screen
// ----------------------------------------------------
class SplashCheckScreen extends StatefulWidget {
  const SplashCheckScreen({super.key});

  @override
  State<SplashCheckScreen> createState() => _SplashCheckScreenState();
}

class _SplashCheckScreenState extends State<SplashCheckScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    // Simulate API/storage check delay
    await Future.delayed(const Duration(seconds: 2)); 
    // Logic to decide the first screen
    String initialRoute;
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;

    if (!seenOnboarding) {
      initialRoute = '/onboarding';
    } else {
      // Check token by attempting to fetch profile (non-blocking)
      final api = ApiService();
      final profile = await api.fetchProfile();
      if (profile != null) {
        AppConfig.isAuthenticated = true;
        initialRoute = '/home';
      } else {
        initialRoute = '/auth';
      }
    }

    // Navigate and remove all previous routes from the stack
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(initialRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Simple loading screen
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.teal),
            SizedBox(height: 16),
            Text('Initializing App...', style: TextStyle(fontSize: 18, color: Colors.teal)),
          ],
        ),
      ),
    );
  }
}
