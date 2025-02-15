import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class MapsScreen extends StatefulWidget {
  @override
  _MapsScreenState createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  late GoogleMapController _mapController;
  LatLng? _currentLocation; // Stores user's real-time location
  bool _isLoading = true; // Loading state
  Set<Marker> _markers = {}; // Stores markers from Firestore

  @override
  void initState() {
    super.initState();
    _getUserLocation(); // Fetch user's current location
  }

  /// 📍 Fetches user's real-time GPS location
  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("❌ Location services are disabled.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) {
          print("❌ Location permissions are permanently denied.");
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      _fetchParkingSpots(); // Load Firestore parking spots
      _moveCameraToUserLocation();
    } catch (e) {
      print("❌ Error getting user location: $e");
    }
  }

  /// 🔄 Moves the map camera to user's location
  void _moveCameraToUserLocation() {
    if (_currentLocation != null && _mapController != null) {
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLocation!, zoom: 16.0),
        ),
      );
    }
  }

  /// 🔥 Fetches parking spots from Firestore and updates map markers
  Future<void> _fetchParkingSpots() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('parkingspots').get();

      Set<Marker> markers = {
        // 🔴 User's current location marker
        if (_currentLocation != null)
          Marker(
            markerId: MarkerId("currentLocation"),
            position: _currentLocation!,
            infoWindow: InfoWindow(title: "You are here"),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
      };

      // 🅿️ Add Firestore parking spots as markers
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        markers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(data["lat"], data["lng"]),
            infoWindow: InfoWindow(
              title: data["name"],
              snippet: "Available: ${data["available_spaces"]} spots",
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          ),
        );
      }

      setState(() {
        _markers = markers;
      });
    } catch (e) {
      print("❌ Error fetching parking spots from Firestore: $e");
    }
  }

  /// 🔐 Logs out the user and redirects to login screen
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("EasyPark Map"),
        actions: [
          IconButton(icon: Icon(Icons.logout), onPressed: () => _logout(context)),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loader while fetching location
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLocation ?? LatLng(45.9456, -66.6413), // Default location if null
                zoom: 16.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _markers,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _moveCameraToUserLocation();
              },
            ),
    );
  }
}
