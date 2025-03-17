import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

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
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _checkAndRequestLocation();
    _fetchParkingSpots();
  }

  Future<void> _checkAndRequestLocation() async {
    try {
      final geolocation = html.window.navigator.geolocation;
      final position = await geolocation.getCurrentPosition();

      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(
          position.coords?.latitude?.toDouble() ?? 0.0,
          position.coords?.longitude?.toDouble() ?? 0.0,
        );
        _isLoading = false;
        _locationError = false;
      });
      _updateUserLocationMarker();
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

  void _updateUserLocationMarker() {
    if (_currentLocation == null) return;
    setState(() {
      _markers
          .removeWhere((marker) => marker.markerId.value == "currentLocation");
      _markers.add(
        Marker(
          markerId: MarkerId("currentLocation"),
          position: _currentLocation!,
          infoWindow: InfoWindow(title: "You are here"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLocation!, zoom: 17.5), // Updated to 17.5
        ),
      );
    }
  }

  Future<void> _fetchParkingSpots() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('parkingspots').get();

      Set<Marker> markers = {};
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        LatLng position = LatLng(data["lat"], data["lng"]);

        markers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: position,
            infoWindow: InfoWindow(
              title: data["name"],
              snippet: "Available: ${data["available_spaces"]} spots",
              onTap: () => _navigateToLocation(position),
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueYellow),
          ),
        );
      }

      setState(() {
        _markers.addAll(markers);
      });
    } catch (e) {
      print("Error fetching parking spots: $e");
    }
  }

  void _navigateToLocation(LatLng destination) async {
    if (_currentLocation == null) {
      print("❌ Error: Current location is not available.");
      return;
    }

    final url =
        "https://www.google.com/maps/dir/?api=1&origin=${_currentLocation!.latitude},${_currentLocation!.longitude}&destination=${destination.latitude},${destination.longitude}&travelmode=driving";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      print("❌ Could not launch $url");
    }
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
        title: Row(
          children: [
            Image.asset(
              'assets/logo.jpg', // Add logo from login page
              height: 30,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 10),
            Text(
              "",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => LoginScreen()));
              }),
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
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _locationError = false;
                                _errorMessage = null;
                              });
                              _checkAndRequestLocation();
                            },
                            child: Text("Retry"),
                          ),
                        ],
                      ),
                    )
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _currentLocation ?? LatLng(37.7749, -122.4194),
                        zoom: 17.5, // Updated to 17.5
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      markers: _markers,
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                        _mapReady = true;
                        if (_currentLocation != null) {
                          _mapController!.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                  target: _currentLocation!, zoom: 17.5),
                            ),
                          );
                        }
                      },
                    ),
        ],
      ),
    );
  }
}