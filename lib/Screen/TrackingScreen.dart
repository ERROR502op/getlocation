import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'datascreen.dart';
import 'locationdata.dart';

class TrackingScreen extends StatefulWidget {
  final String userName;
  TrackingScreen({required this.userName});
  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  DatabaseReference _firebaseRef =
  FirebaseDatabase.instance.reference().child('users').child('USER_ID');

  List<LocationData> locationDataList = [];
  late GoogleMapController _mapController;
  List<Marker> _markers = [];
  Set<Polyline> _polylines = {};
  int _currentMarkerIndex = 0;
  double currentLatitude = 0.0;
  double currentLongitude = 0.0;
  double stopLatitude = 0.0; // Set the latitude where you want to stop updating the polyline
  double stopLongitude = 0.0; // Set the longitude where you want to stop updating the polyline
  int _lastMarkerIndex = 0;
  BitmapDescriptor customMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);


  @override
  void initState() {
    super.initState();
    _firebaseRef = FirebaseDatabase.instance.reference().child('users').child(widget.userName);
    _loadMarkers();
    // Start the timer to update the location every 2 seconds
    Timer.periodic(Duration(seconds: 2), (Timer timer) {
      _updateLocation();
    });
    Future.delayed(Duration(milliseconds: 500), () {
      if (_markers.isNotEmpty) {
        _mapController.animateCamera(CameraUpdate.newLatLng(_markers[0].position));
      }
    });
  }


  Future<void> _loadMarkers() async {
    _firebaseRef!.onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? values = event.snapshot.value as Map<dynamic, dynamic>?;

        if (values != null) {
          List<Marker> markerList = [];
          List<Polyline> polylineList = [];

          values.forEach((key, value) {
            double latitude = value['latitude'] ?? 0.0;
            double longitude = value['longitude'] ?? 0.0;
            String markerId = key.toString();

            Marker marker = Marker(
              markerId: MarkerId(markerId),
              position: LatLng(latitude, longitude),
              infoWindow: InfoWindow(title: widget.userName),
            );
            markerList.add(marker);
          });

          for (int i = 1; i < markerList.length; i++) {
            LatLng lastPosition = markerList[i - 1].position;
            LatLng currentPosition = markerList[i].position;
            Polyline polyline = Polyline(
              polylineId: PolylineId('polyline_$i'),
              points: [lastPosition, currentPosition],
              color: Colors.blue,
              width: 2,
            );
            polylineList.add(polyline);
          }

          setState(() {
            _markers = markerList;
            _lastMarkerIndex = markerList.length - 1; // Set the last marker index
            _mapController.animateCamera(CameraUpdate.newLatLng(_markers.first.position));
            _polylines = Set<Polyline>.of(polylineList);
          });

        }
      }
    });

  }
  void _updateLocation() {
    if (_markers.isNotEmpty) {
      setState(() {
        _currentMarkerIndex = (_currentMarkerIndex + 1) % _markers.length;
        currentLatitude = _markers[_currentMarkerIndex].position.latitude;
        currentLongitude = _markers[_currentMarkerIndex].position.longitude;

        if (currentLatitude == stopLatitude && currentLongitude == stopLongitude) {
          return; // Stop updating the polyline once the marker reaches the stopLatitude and stopLongitude.
        }

        if (_currentMarkerIndex > 0) {
          LatLng lastPosition = _markers[_currentMarkerIndex - 1].position;
          LatLng currentPosition = _markers[_currentMarkerIndex].position;
          Polyline polyline = Polyline(
            polylineId: PolylineId('currentPolyline'),
            points: [lastPosition, currentPosition],
            color: Colors.green, // Adjust the color of the updated polyline
            width: 3, // Set the width of the updated polyline
          );
          _polylines.add(polyline); // Add the updated polyline to the set of polylines

          if (_currentMarkerIndex == _lastMarkerIndex) {
            // Draw the final polyline between the first and last markers (source and destination)
            LatLng firstPosition = _markers[0].position;
            Polyline finalPolyline = Polyline(
              polylineId: PolylineId('finalPolyline'),
              points: [firstPosition, currentPosition],
              color: Colors.red, // Adjust the color of the final polyline
              width: 3, // Set the width of the final polyline
            );
            _polylines.add(finalPolyline); // Add the final polyline to the set of polylines

            // Add a new marker for the current location
            Marker newMarker = Marker(
              markerId: MarkerId('currentLocationMarker'),
              position: currentPosition,
              icon: customMarkerIcon, // Set the custom marker icon
              infoWindow: InfoWindow(title: widget.userName),
            );
            _markers.add(newMarker);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_rounded),
        ),
        title: Text('Map with Markers'),
      ),
      body: GoogleMap(
        markers: Set<Marker>.of(_markers.isNotEmpty
            ? [_markers[_currentMarkerIndex]]
            : []), // Show only the current marker if available
        polylines: _polylines,
        onMapCreated: (controller) {
          _mapController = controller;
        },
        initialCameraPosition: CameraPosition(
          target: LatLng(0, 0), // Set initial camera position to your desired location.
          zoom: 50.0,
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Latitude: ${currentLatitude.toStringAsFixed(5)}, '
                    'Longitude: ${currentLongitude.toStringAsFixed(5)}',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}