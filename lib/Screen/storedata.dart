import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'locationdata.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataScreen extends StatefulWidget {
  @override
  _DataScreenState createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  DatabaseReference? _firebaseRef;
  List<LocationData> locationDataList = [];

  @override
  void initState() {
    super.initState();
    _fetchUserIdAndData();
  }

  void _fetchUserIdAndData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString('NameOfUser');

    if (userId != null) {
      _firebaseRef = FirebaseDatabase.instance.reference().child('users').child(userId);
      _fetchLocationData();
    }
  }

  void _fetchLocationData() {
    _firebaseRef!.once().then((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? values = event.snapshot.value as Map<dynamic, dynamic>?;

        if (values != null) {
          locationDataList.clear();
          values.forEach((key, value) {
            String userName = key; // User ID is the key in this case
            double latitude = (value['latitude'] ?? 0).toDouble();
            double longitude = (value['longitude'] ?? 0).toDouble();
            int timestamp = value['timestamp'] ?? 0;
            LocationData locationData = LocationData(
                latitude, longitude, timestamp, userName);
            locationDataList.add(locationData);
          });
          setState(() {});
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location Data'),
      ),
      body: ListView.builder(
        itemCount: locationDataList.length,
        itemBuilder: (context, index) {
          LocationData data = locationDataList[index];
          return ListTile(
            title: Text('User: ${data.userName}'),
            subtitle: Text(
                'Latitude: ${data.latitude}, Longitude: ${data.longitude}'),
            trailing: Text('Timestamp: ${DateTime.fromMillisecondsSinceEpoch(
                data.timestamp)}'),
          );
        },
      ),
    );
  }
}
