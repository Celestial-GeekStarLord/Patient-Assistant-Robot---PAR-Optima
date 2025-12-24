import 'package:flutter/material.dart';
import '../src/screens/login.dart'; // Import your file

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LoginPage(), // This tells the app to start on the Login Page
  ));
}