import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class MapsScreen extends StatefulWidget {
  @override
  _MapsScreenState createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  bool _isLoading = true;
  bool _locationError = false;
  String? _errorMessage;
  Set<Marker> _markers = {};
  StreamSubscription? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _checkAndRequestLocation();
  }

  /// 📍 Check Geolocation Support and Fetch Location
  Future<void> _checkAndRequestLocation() async {
    try {
      // Check if geolocation is supported by the browser
      if (html.window.navigator.geolocation == null) {
        setState(() {
          _isLoading = false;
          _locationError = true;
          _errorMessage = "Geolocation is not supported by this browser.";
        });
        return;
      }

      await _getWebLocation();
    } catch (e) {
      print("❌ Error checking geolocation: $e");
      setState(() {
        _isLoading = false;
        _locationError = true;
        _errorMessage = "Error accessing geolocation: $e";
      });
    }
  }

  /// 📍 Fetch Location Using Browser Geolocation API
  Future<void> _getWebLocation() async {
    try {
      print("📍 Attempting to fetch web location...");
      final geolocation = html.window.navigator.geolocation;
      final position = await geolocation.getCurrentPosition();
      print(
          "📍 Web Geolocation: ${position.coords?.latitude?.toDouble() ?? 0.0}, ${position.coords?.longitude?.toDouble() ?? 0.0}");

      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(
          position.coords?.latitude?.toDouble() ?? 0.0,
          position.coords?.longitude?.toDouble() ?? 0.0,
        );
        _isLoading = false;
        _locationError = false;
      });

      _fetchParkingSpots();
      _startRealTimeLocationUpdates();
    } catch (e) {
      print("❌ Error getting web location: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _locationError = true;
        _errorMessage = "Failed to get location: $e";
      });
    }
  }

  /// 🔄 Start Real-Time Location Updates Using Browser WatchPosition
  void _startRealTimeLocationUpdates() {
    final geolocation = html.window.navigator.geolocation;
    _positionStreamSubscription = geolocation.watchPosition().listen(
      (position) {
        if (!mounted) return;
        setState(() {
          _currentLocation = LatLng(
            position.coords?.latitude?.toDouble() ?? 0.0,
            position.coords?.longitude?.toDouble() ?? 0.0,
          );
        });
        print(
            "📍 Web Live Location: ${position.coords?.latitude?.toDouble() ?? 0.0}, ${position.coords?.longitude?.toDouble() ?? 0.0}");
        _updateUserLocationMarker();
      },
      onError: (e) {
        print("❌ Error in web location stream: $e");
        if (!mounted) return;
        setState(() {
          _locationError = true;
          _errorMessage = "Location tracking error: $e";
        });
      },
    );
  }

  /// 🔄 Move Camera to User's Current Location
  void _moveCameraToUserLocation() {
    if (_mapController != null && _currentLocation != null) {
      print(
          "🔄 Moving camera to: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}");
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLocation!, zoom: 18.0),
        ),
      );
    }
  }

  /// 🔥 Fetch Parking Spots from Firestore
  Future<void> _fetchParkingSpots() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('parkingspots').get();
      print("✅ Loaded ${snapshot.docs.length} parking spots from Firestore.");

      Set<Marker> markers = {};
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

      if (!mounted) return;
      setState(() {
        _markers = markers;
      });
      _updateUserLocationMarker();
    } catch (e) {
      print("❌ Error fetching parking spots: $e");
    }
  }

  /// 🏷️ Update User's Location Marker on Map
  void _updateUserLocationMarker() {
    if (_currentLocation == null) return;
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == "currentLocation");
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

  /// 🔐 Logout Function
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  /// 🔄 Retry Fetching Location
  void _retryFetchingLocation() {
    setState(() {
      _isLoading = true;
      _locationError = false;
      _errorMessage = null;
    });
    _checkAndRequestLocation();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
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
      body: Stack(
        children: [
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _locationError
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _errorMessage ?? "Unable to fetch location.",
                            style: TextStyle(color: Colors.red, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _retryFetchingLocation,
                            child: Text("Retry"),
                          ),
                        ],
                      ),
                    )
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _currentLocation ?? LatLng(0, 0),
                        zoom: 16.0,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      markers: _markers,
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                        if (_currentLocation != null) {
                          _moveCameraToUserLocation();
                        }
                      },
                    ),
        ],
      ),
    );
  }
}