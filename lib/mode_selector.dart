import 'package:flutter/material.dart';
import 'src/screens/admin_interface.dart';
import 'src/screens/patient_interface.dart';

class ModeSelector extends StatelessWidget {
  const ModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("PAR OPTIMA", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
            _btn(context, "PATIENT MODE", const PatientInterface()),
            const SizedBox(height: 20),
            _btn(context, "STAFF MODE", const AdminInterface()),
          ],
        ),
      ),
    );
  }

  Widget _btn(BuildContext context, String txt, Widget page) {
    return ElevatedButton(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => page)),
      child: Text(txt),
    );
  }
}