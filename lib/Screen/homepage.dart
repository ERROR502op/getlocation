import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:getlocation/Screen/mapscreen.dart';
import 'package:getlocation/Screen/TrackingScreen.dart';


class HomePage extends StatefulWidget {


  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> userNames = [];


  @override
  void initState() {
    super.initState();
    _fetchUserNamesFromDatabase();
  }

  void _fetchUserNamesFromDatabase() async {
    List<String> names = await _fetchUserNames();
    setState(() {
      userNames = names;
    });
  }
  Future<List<String>> _fetchUserNames() async {
    List<String> userNames = [];
    DatabaseReference firebaseRef = FirebaseDatabase.instance.reference().child('users');
    await firebaseRef.once().then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        Map<dynamic, dynamic> usersData = snapshot.value as Map<dynamic, dynamic>;

        usersData.forEach((key, value) {
          // Assuming 'key' is the user name, add it to the list
          userNames.add(key);
        });
      }
    });

    return userNames;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simple Flutter Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Text('All Users',style: TextStyle(fontWeight: FontWeight.bold),),
            Expanded(
              child: ListView.builder(
                itemCount: userNames.length,
                itemBuilder: (context, index) {
                  String userName = userNames[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30,vertical: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle tracking for the selected user
                        // For example, navigate to a tracking screen with the user's name
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TrackingScreen(userName: userName)),
                        );
                      },
                      child: Text('Track $userName'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}