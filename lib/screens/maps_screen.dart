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
  bool _hasFetchedLocation = false; // Prevent double fetch
  bool _mapReady = false; // Track map initialization
  bool _isManuallySettingLocation = false; // Track manual location mode

  @override
  void initState() {
    super.initState();
    if (!_hasFetchedLocation) {
      _checkAndRequestLocation().then((_) {
        if (_currentLocation != null && _mapReady) {
          _fetchParkingSpots(); // Load parking spots after initial location
        }
      });
    }
  }

  /// 📍 Check Geolocation Support and Fetch Location with High Accuracy
  Future<void> _checkAndRequestLocation() async {
    if (_hasFetchedLocation) {
      print("📍 Already fetched location, skipping...");
      return;
    }

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

      // Request high-accuracy location
      _hasFetchedLocation = true;
      await _getWebLocation(enableHighAccuracy: true);
    } catch (e) {
      print("❌ Error checking geolocation: $e");
      setState(() {
        _isLoading = false;
        _locationError = true;
        _errorMessage = "Error accessing geolocation: $e";
      });
    }
  }

  /// 📍 Fetch Location Using Browser Geolocation API with High Accuracy
  Future<void> _getWebLocation({bool enableHighAccuracy = false}) async {
    try {
      print("📍 Attempting to fetch web location with high accuracy: $enableHighAccuracy...");
      final geolocation = html.window.navigator.geolocation;
      final position = await geolocation.getCurrentPosition(
        enableHighAccuracy: enableHighAccuracy,
        maximumAge: Duration(milliseconds: 0), // Ensure fresh location
        timeout: Duration(seconds: 15), // Timeout after 15 seconds
      );
      final lat = position.coords?.latitude?.toDouble() ?? 0.0;
      final lon = position.coords?.longitude?.toDouble() ?? 0.0;
      print("📍 Web Geolocation: $lat, $lon");

      if (!mounted) return;
      if (lat == 0.0 && lon == 0.0) {
        setState(() {
          _locationError = true;
          _errorMessage = "Failed to get location. Set your location manually.";
        });
        return;
      }

      setState(() {
        _currentLocation = LatLng(lat, lon);
        _isLoading = false;
        _locationError = false;
      });

      if (_mapReady) {
        _fetchParkingSpots();
      }
    } catch (e) {
      print("❌ Error getting web location: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _locationError = true;
        _errorMessage = "Failed to get location: $e. Set your location manually.";
      });
    }
  }

  /// 🔄 Move Camera to User's Current Location
  void _moveCameraToUserLocation() {
    if (_mapController != null && _currentLocation != null && _mapReady) {
      print(
          "🔄 Moving camera to: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}");
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLocation!, zoom: 18.0),
        ),
      );
    } else {
      print("⚠️ Cannot move camera: Map not ready or location null");
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
          infoWindow: InfoWindow(
            title: "You are here",
            snippet: "Manually Set or Initial Location",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });
    _moveCameraToUserLocation();
  }

  /// 🖱️ Handle Manual Location Setting
  void _onMapTapped(LatLng position) {
    if (_isManuallySettingLocation) {
      setState(() {
        _currentLocation = position;
        _locationError = false;
        _errorMessage = null;
        _isManuallySettingLocation = false;
      });
      if (_mapReady) {
        _updateUserLocationMarker();
        _fetchParkingSpots(); // Refresh parking spots based on manual location
      }
    }
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
      _hasFetchedLocation = false; // Allow retry
      _isManuallySettingLocation = false;
      _currentLocation = null; // Reset current location
    });
    _checkAndRequestLocation().then((_) {
      if (_currentLocation != null && _mapReady) {
        _fetchParkingSpots(); // Ensure parking spots load after retry
      }
    });
  }

  /// 🖱️ Start Manual Location Setting
  void _startManualLocationSetting() {
    setState(() {
      _isManuallySettingLocation = true;
      _errorMessage = "Tap on the map to set your exact location.";
    });
  }

  @override
  void dispose() {
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
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? LatLng(0, 0),
              zoom: 18.0, // Tighter zoom for better detail
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _mapReady = true; // Mark map as ready
              if (_currentLocation != null) {
                _moveCameraToUserLocation();
                _fetchParkingSpots(); // Load parking spots after map is ready
              }
            },
            onTap: _onMapTapped, // Allow manual location setting
          ),
          if (_isLoading)
            Center(child: CircularProgressIndicator()),
          if (_locationError && !_isLoading)
            Center(
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
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _startManualLocationSetting,
                    child: Text("Set Location Manually"),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}