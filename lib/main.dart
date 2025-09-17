import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'home.dart';
import 'me_page.dart';
import 'startRun.dart';
import 'insights.dart';
import 'create_new_account.dart';
import 'profile.dart';
import 'edit.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ruvia',
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomePage(),
        '/me': (context) => MePage(),
        '/run': (context) => StartRunPage(),
        '/insights': (context) => InsightsPage(),
        '/create': (context) => CreateAccountScreen(),
        '/profile': (context) => ProfilePage(),
        '/edit': (context) => EditProfilePage(),
      },
      home: const SplashScreenGate(),
    );
  }
}

// Splash screen that waits for BOTH the timer and Firebase
class SplashScreenGate extends StatefulWidget {
  const SplashScreenGate({super.key});
  @override
  State<SplashScreenGate> createState() => _SplashScreenGateState();
}

class _SplashScreenGateState extends State<SplashScreenGate> {
  bool _timerDone = false;
  bool _firebaseReady = false;
  User? _user;

  @override
  void initState() {
    super.initState();

    // 3s timer
    Future.delayed(const Duration(milliseconds: 3000), () {
      setState(() => _timerDone = true);
    });

    // Wait for first Firebase user event
    FirebaseAuth.instance.authStateChanges().first.then((user) {
      if (mounted) {
        setState(() {
          _firebaseReady = true;
          _user = user;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_timerDone || !_firebaseReady) {
      return const SplashScreen(); // Show your custom animated splash screen
    } else {
      // After both timer and Firebase: show correct initial page
      if (_user != null) {
        return HomePage();
      } else {
        return LoginScreen();
      }
    }
  }
}
