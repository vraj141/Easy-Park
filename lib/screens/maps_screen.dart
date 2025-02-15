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
  late Stream<Position> _positionStream; // 🔥 For real-time GPS tracking

  @override
  void initState() {
    super.initState();
    _getUserLocation(); // Fetch user's accurate location
  }

  /// 📍 **Fetch User's Real-Time GPS Location with High Accuracy**
  Future<void> _getUserLocation() async {
    try {
      // ✅ **Check if location services are enabled**
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("❌ Location services are disabled.");
        return;
      }

      // ✅ **Request location permissions**
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) {
          print("❌ Location permissions are permanently denied.");
          return;
        }
      }

      // ✅ **Get current location with high accuracy**
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation, // **Maximum Accuracy**
        forceAndroidLocationManager: true, // ✅ **Ensures high accuracy on Android**
      );

      print("📍 Accurate Location: ${position.latitude}, ${position.longitude}");

      if (!mounted) return; // Prevent calling setState after widget is disposed

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      _fetchParkingSpots(); // Load parking spots from Firestore

      // ✅ **Start real-time location updates**
      _positionStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
      );

      _positionStream.listen((Position position) {
        if (!mounted) return;
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });

        print("📍 Updated Live Location: ${position.latitude}, ${position.longitude}");

        _updateUserLocationMarker(); // ✅ **Updates user marker dynamically**
      });

    } catch (e) {
      print("❌ Error getting user location: $e");
    }
  }

  /// 🔄 **Moves the Map Camera to User's Updated Location**
  void _moveCameraToUserLocation() {
    if (_currentLocation != null && _mapController != null) {
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLocation!, zoom: 16.0),
        ),
      );
    }
  }

  /// 🔥 **Fetch Parking Spots from Firestore**
  Future<void> _fetchParkingSpots() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('parkingspots').get();
      print("✅ Fetched ${snapshot.docs.length} parking spots from Firestore.");

      Set<Marker> markers = {};

      // 🅿️ **Add Firestore parking spots as markers**
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

      if (!mounted) return; // Prevent setState after widget is disposed

      setState(() {
        _markers = markers;
      });

      _updateUserLocationMarker(); // ✅ **Ensures user marker is updated**
    } catch (e) {
      print("❌ Error fetching parking spots from Firestore: $e");
    }
  }

  /// 🏷️ **Update User's Location Marker on Map**
  void _updateUserLocationMarker() {
    if (_currentLocation == null) return;

    setState(() {
      // **Remove previous user location marker**
      _markers.removeWhere((marker) => marker.markerId.value == "currentLocation");

      // **Add updated user location marker**
      _markers.add(
        Marker(
          markerId: MarkerId("currentLocation"),
          position: _currentLocation!,
          infoWindow: InfoWindow(title: "You are here"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });

    _moveCameraToUserLocation();
  }

  /// 🔐 **Logs out the user and redirects to login screen**
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
                target: _currentLocation ?? LatLng(0, 0), // **Prevents crash if location is null**
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
