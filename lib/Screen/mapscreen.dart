import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:getlocation/Screen/homepage.dart';
import 'package:getlocation/Screen/storedata.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'datascreen.dart';

class MapScreen extends StatefulWidget {


  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  String _locationMessage = '';
  LatLng _userLocation = LatLng(0, 0); // Default value for the user's location
  bool _isStandingStill = false;
  int _standingTime = 0; // In seconds
  Timer? _standingTimer;
  BitmapDescriptor customMarkerIcon = BitmapDescriptor.defaultMarker;
  String standingTimeText = '';
  Set<Marker> markers = {}; // Set to store markers on the map

  final DatabaseReference _firebaseRef = FirebaseDatabase.instance.reference();


  @override
  void initState() {
    super.initState();
    _getLocationPermission();

  }

  void _getLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isGranted) {
      _getLocation();
    } else if (status.isDenied || status.isRestricted) {
      if (await Permission.locationWhenInUse.request().isGranted) {
        _getLocation();
      } else {
        setState(() {
          _locationMessage = 'Location permission denied';
        });
      }
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _locationMessage =
        'Location permission permanently denied. Please open app settings and grant the permission manually.';
      });
    }
    _startStandingTimer();
  }

  void _startStandingTimer() {
    _standingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_isStandingStill) {
        setState(() {
          _standingTime++;
        });
      }
      _loadCustomMarkerIcon();
    });
    Timer.periodic(Duration(seconds: 2), (timer) {
      _getLocation();
    });
  }

  void _loadCustomMarkerIcon() {
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(), "assets/image/3-removebg-preview.png")
        .then((icon) {
      setState(() {
        customMarkerIcon = icon;
      });
    });
  }

  void _getLocation() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    var NameofUser = pref.getString("NameOfUser");
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Check if the user's location has changed since the last update
      bool locationChanged =
          _userLocation.latitude != position.latitude ||
              _userLocation.longitude != position.longitude;

      bool isStandingStill = _isUserStandingStill(position);

      setState(() {
        _locationMessage =
        'Latitude: ${position.latitude}, Longitude: ${position.longitude}';
        _userLocation = LatLng(position.latitude, position.longitude);

        // Restart the standing timer if the location has changed
        if (locationChanged) {
          _isStandingStill = false;
          _standingTime = 0;
        }

        // When the user's position is updated, check if the user is standing still
        if (isStandingStill) {
          if (!_isStandingStill) {
            _isStandingStill = true;
            _standingTime = 0;
          }
        } else {
          // If the user is not standing still, stop the timer
          _stopStandingTimer();
        }

        // Update the marker's position on the map
        // Clear previous markers and add a new marker for the updated user location
        markers.clear();
        markers.add(
          Marker(
            markerId: MarkerId('user_location'),
            position: _userLocation,
            icon: customMarkerIcon,
            infoWindow: InfoWindow(
              title: NameofUser,
              snippet: 'Time: ${DateTime.now().toLocal().toString()}',
            ),
          ),
        );
        _mapController?.animateCamera(CameraUpdate.newLatLng(_userLocation));
      });

      // Insert the updated latitude, longitude, and timestamp into the database
      _firebaseRef.child('users').child(NameofUser ?? '').push().set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      _locationMessage = 'Error getting location: $e';
    }
  }

  bool _isUserStandingStill(Position newPosition) {
    final double threshold = 5.0;

    if (_userLocation == LatLng(0, 0)) {
      // If the user's previous position is the default one, consider them standing still.
      return true;
    }

    // Calculate the distance between the old and new positions using the Haversine formula.
    double distance = Geolocator.distanceBetween(
      _userLocation.latitude,
      _userLocation.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    // If the distance is less than the threshold, consider the user standing still.
    return distance < threshold;
  }

  void _stopStandingTimer() {
    if (_isStandingStill) {
      setState(() {
        _isStandingStill = false;
      });
    }
  }

  Future<void> initializeService() async {
    final service = FlutterBackgroundService();
    AndroidNotificationChannel channel = AndroidNotificationChannel(
      "script academy",
      "foreground service",
      importance: Importance.high,
    );
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      iosConfiguration: IosConfiguration(),
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        autoStart: true,
        notificationChannelId: "script academy",
        initialNotificationTitle: "foreground service",
        initialNotificationContent: "initializing",
        foregroundServiceNotificationId: 888,
      ),
    );
    service.startService();
  }

  @pragma('vm-entry-point')
  void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    // Android-specific event listeners
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });
      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Background task logic using Timer
    Timer.periodic(Duration(seconds: 2), (timer) async {
      if (service is AndroidServiceInstance) {
        // Check if the service is running in the foreground
        if (await service.isForegroundService()) {
          // Get the current location using Geolocator
          _getLocation();
        }
      }
    });
  }

  @override
  void dispose() {
    _standingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int standingTimeMinutes = _standingTime ~/ 60;
    int standingTimeSeconds = _standingTime % 60;

    standingTimeText =
    'Time Standing Still: $standingTimeMinutes minutes $standingTimeSeconds seconds';

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Location App'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _locationMessage,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                standingTimeText,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _userLocation,
                    zoom:70.25,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  markers: markers,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => HomePage()));
            },
            child: Text("Track")),
      ),
    );
  }
}
