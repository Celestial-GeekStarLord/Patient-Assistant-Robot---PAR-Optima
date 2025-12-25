import 'package:flutter/material.dart';
import 'report.dart';
// Import your profile view page here
// import 'patient_profile_view.dart';

class PatientDetailsPage extends StatelessWidget {
  const PatientDetailsPage({super.key});

  final Color primaryNavy = const Color(0xFF0D47A1);
  final Color headerBlue = Colors.blue; // Specific blue for headers

  @override
  Widget build(BuildContext context) {
    // Dummy Data
    final List<Map<String, String>> patients = [
      {"sn": "1", "id": "P001", "name": "John Doe", "room": "402"},
      {"sn": "2", "id": "P002", "name": "Jane Smith", "room": "405"},
      {"sn": "3", "id": "P003", "name": "Robert Brown", "room": "310"},
      {"sn": "4", "id": "P004", "name": "Emily Davis", "room": "202"},
      {"sn": "5", "id": "P005", "name": "Michael Wilson", "room": "101"},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("PATIENT RECORDS",
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: Colors.white,
        foregroundColor: primaryNavy,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Tap a row to view full medical history",
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 20),

            // --- THE TABLE CARD ---
            Card(
              elevation: 3,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Container(
                width: double.infinity,
                // --- HORIZONTAL SCROLL FIX ---
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 35, // Space between columns
                    showCheckboxColumn: false,
                    headingRowColor: WidgetStateProperty.all(headerBlue.withOpacity(0.05)),
                    columns: [
                      _buildHeader('S.N'),
                      _buildHeader('Patient ID'),
                      _buildHeader('Name'),
                      _buildHeader('Room No'),
                    ],
                    rows: patients.map((patient) {
                      return DataRow(
                        onSelectChanged: (selected) {
                          if (selected != null && selected) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReportPage(),
                              ),
                            );
                            // ));
                          }
                        },
                        cells: [
                          _buildDataCell(patient['sn']!),
                          _buildDataCell(patient['id']!),
                          _buildDataCell(patient['name']!),
                          _buildDataCell(patient['room']!),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for Styled Headers (Blue Color)
  DataColumn _buildHeader(String label) {
    return DataColumn(
      label: Text(
        label,
        style: TextStyle(
          color: headerBlue, // BLUE HEADERS
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  // Helper for Data Cells (Black Color)
  DataCell _buildDataCell(String text) {
    return DataCell(
      Text(
        text,
        style: const TextStyle(
          color: Colors.black, // BLACK DATA
          fontSize: 14,
        ),
      ),
    );
  }
}