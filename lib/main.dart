import 'package:flutter/material.dart';
//import '../src/screens/login.dart'; // Import your file
import '../src/screens/robot_interface.dart';
void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: RobotInterface(), // This tells the app to start on the Login Page
  ));
}