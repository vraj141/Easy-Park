import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'maps_screen.dart'; // Import MapsScreen

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("EasyPark"),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Welcome, ${user?.displayName ?? 'User'}! 👋",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Let's find the best parking spot nearby you!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MapsScreen()),
                );
              },
              child: Text("Find My Location"),
            ),
          ],
        ),
      ),
    );
  }
}
