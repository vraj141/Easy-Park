import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class MapsScreen extends StatefulWidget {
  @override
  _MapsScreenState createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  late GoogleMapController _mapController;
  LatLng? _currentLocation;
  bool _isLoading = true;
  Set<Marker> _markers = {};

  // 🅿️ Temporary parking spots (Actual university locations)
  List<Map<String, dynamic>> _parkingSpots = [
    {"lat": 45.9456, "lng": -66.6413, "name": "Aitken Centre Parking", "available_spaces": 5},
    {"lat": 45.9482, "lng": -66.6425, "name": "Head Hall Parking", "available_spaces": 3},
    {"lat": 45.9468, "lng": -66.6409, "name": "MacLaggan Hall Parking", "available_spaces": 7},
    {"lat": 45.9449, "lng": -66.6410, "name": "Lady Beaverbrook Gym Parking", "available_spaces": 2},
    {"lat": 45.9501, "lng": -66.6432, "name": "Student Union Building Parking", "available_spaces": 10},
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  // 📍 Get User's Location
  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _isLoading = false;
    });

    _loadParkingMarkers();

    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentLocation!, zoom: 16.0), // Medium zoom level
      ),
    );
  }

  // 📍 Add markers for parking spots
  void _loadParkingMarkers() {
    Set<Marker> markers = {
      // User's current location - RED marker
      Marker(
        markerId: MarkerId("currentLocation"),
        position: _currentLocation!,
        infoWindow: InfoWindow(title: "You are here"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),

      // Parking spots - YELLOW markers
      for (var spot in _parkingSpots)
        Marker(
          markerId: MarkerId(spot["name"]),
          position: LatLng(spot["lat"], spot["lng"]),
          infoWindow: InfoWindow(
            title: spot["name"],
            snippet: "Available: ${spot["available_spaces"]} spots",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        ),
    };

    setState(() {
      _markers = markers;
    });
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("EasyPark Map"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loader while fetching location
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLocation ?? LatLng(45.9456, -66.6413), // Default location if null
                zoom: 16.0, // Medium zoom level for visibility
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _markers,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                if (_currentLocation != null) {
                  _mapController.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(target: _currentLocation!, zoom: 16.0),
                    ),
                  );
                }
              },
            ),
    );
  }
}
