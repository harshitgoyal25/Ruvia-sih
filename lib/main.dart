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
      title: 'INTVL',
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomePage(),
        '/me': (context) => MePage(),
        '/run': (context) => StartRunPage(),
        '/insights': (context) => InsightsPage(),
        '/create': (context) => CreateAccountScreen(),
        '/profile':(context)=> ProfilePage(),
        '/edit':(context)=> EditProfilePage(),
      },
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // If user is logged in, show home, else login
        if (snapshot.hasData && snapshot.data != null) {
          return HomePage();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}
