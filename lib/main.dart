import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'home.dart';
import 'me_page.dart';
import 'startRun.dart';
import 'insights.dart';
import 'create_new_account.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Firebase initialized'); // <- should appear in console
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'INTVL',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomePage(),
        '/me': (context) => MePage(),
        '/run': (context) => StartRunPage(),
        '/insights': (context) => InsightsPage(),
        '/create': (context) => CreateAccountScreen(),
      },
    );
  }
}