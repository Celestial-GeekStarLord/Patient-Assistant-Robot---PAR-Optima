import 'package:flutter/material.dart';
import 'id_entry.dart';
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // These controllers capture what the user types
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Define our theme colors locally for easy use
  final Color skyBlue = Color(0xFF87CEEB);
  final Color offWhite = Color(0xFFFAF9F6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: offWhite, // Set the background to Off-White
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Icon / Logo
                Icon(Icons.local_hospital, size: 100, color: skyBlue),
                SizedBox(height: 20),

                // 2. Title
                Text(
                  "Hospital Portal",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                SizedBox(height: 40),

                // 3. Username Field
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    hintText: "Username",
                    prefixIcon: Icon(Icons.person, color: skyBlue),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // 4. Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: true, // Hides the password dots
                  decoration: InputDecoration(
                    hintText: "Password",
                    prefixIcon: Icon(Icons.lock, color: skyBlue),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 40),

                // 5. Login Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      // Logic for login goes here
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => IdEntryPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: skyBlue, // Sky Blue button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "LOGIN",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}