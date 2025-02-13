import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/maps_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyD3YJf3544zFcl2W17Cgx4BAJ3M4pjTNV8",
      authDomain: "easypark141.firebaseapp.com",
      projectId: "easypark141",
      storageBucket: "easypark141.firebasestorage.app",
      messagingSenderId: "1098576921917",
      appId: "1:1098576921917:web:cb174f4c5acb7a273b3154",
      measurementId: "G-9MJXH3W125",
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyPark',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: AuthCheck(),
    );
  }
}

// 🔥 AUTH CHECK - Redirects User to Login or Maps
class AuthCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return MapsScreen(); // Logged in, go to maps
        } else {
          return LoginScreen(); // Not logged in, go to login
        }
      },
    );
  }
}
