import 'package:flutter/material.dart';
import 'package:getlocation/Screen/mapscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController _nameController = TextEditingController();
  String _generatedID = '';
  String? name;




  // Generate a random ID (for demo purposes)
  String _generateID() {
    // Implement your ID generation logic here.
    // For simplicity, we'll use a random number as an example.
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  void _onNextButtonPressed() async {
    String name = _nameController.text.trim();

    // Check if the name field is empty
    if (name.isEmpty) {
      // Display an error message and return early
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Please enter your name.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // If the name is not empty, proceed to the next screen
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setString("NameOfUser", name);
    String id = _generateID();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Enter Your name",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onNextButtonPressed,
              child: Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
