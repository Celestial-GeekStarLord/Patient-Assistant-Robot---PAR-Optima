import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider package

// 🛑 REMOVED: import 'package:cloud_firestore/cloud_firestore.dart';
// 🛑 REMOVED: The entire PatientRecord class definition was here.

// 🛑 REQUIRED IMPORTS: Use the centralized models and provider
import '../providers/user_provider.dart';
import '../models/patient_record.dart'; // <--- Use the centralized model
import 'report.dart';


class PatientDetailsPage extends StatefulWidget {
  const PatientDetailsPage({super.key});

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  final Color primaryNavy = const Color(0xFF0D47A1);
  final Color headerBlue = Colors.blue;

  @override
  void initState() {
    super.initState();
    // 🛑 ACTION: Trigger the UserProvider to fetch the patient list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // listen: false is crucial here as it's inside initState
      Provider.of<UserProvider>(context, listen: false).fetchPatientList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🛑 ACCESS DATA: Use Consumer to listen to changes in UserProvider
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // 🛑 DATA SOURCE: Get data directly from the provider
        // Now using the PatientRecord type imported from ../models/patient_record.dart
        final List<PatientRecord> patients = userProvider.patientList;
        final bool isLoading = userProvider.isPatientListLoading;
        final String? errorMessage = userProvider.patientListError;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text("PATIENT RECORDS",
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            backgroundColor: Colors.white,
            foregroundColor: primaryNavy,
            elevation: 0,
            actions: [
              IconButton(
                // 🛑 ACTION: Refresh calls the fetch method on the Provider
                icon: const Icon(Icons.refresh),
                onPressed: () => userProvider.fetchPatientList(),
                tooltip: 'Refresh Data',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tap a row to view full medical history",
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 20),

                // --- LOADING / ERROR STATE ---
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (errorMessage != null)
                  Center(
                    // Display the error message retrieved from the provider
                    child: Text(errorMessage, style: const TextStyle(color: Colors.red)),
                  )
                else if (patients.isEmpty)
                    const Center(
                      child: Text("No patient records found.", style: TextStyle(color: Colors.grey)),
                    )

                  // --- THE TABLE CARD ---
                  else
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
                              _buildHeader('Custom ID'),
                              _buildHeader('Name'),
                              _buildHeader('Channel ID'),
                              _buildHeader('Action'),
                            ],
                            rows: List.generate(patients.length, (index) {
                              final patient = patients[index];
                              return DataRow(
                                onSelectChanged: (selected) {
                                  if (selected != null && selected) {
                                    _navigateToReport(context, patient);
                                  }
                                },
                                cells: [
                                  _buildDataCell((index + 1).toString()), // S.N.
                                  _buildDataCell(patient.customId), // Patient's custom ID
                                  _buildDataCell(patient.name), // Name
                                  _buildDataCell(patient.channelId), // RTDB Channel ID
                                  DataCell(
                                    IconButton(
                                      icon: Icon(Icons.arrow_forward_ios, size: 16, color: primaryNavy),
                                      onPressed: () => _navigateToReport(context, patient),
                                    ),
                                  ),
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
      },
    );
  }

  // Helper function to handle navigation
  void _navigateToReport(BuildContext context, PatientRecord patient) {
    // Pass the channelId to ReportPage for fetching real-time data
    debugPrint('Navigating to Report for Patient: ${patient.name} (Channel ID: ${patient.channelId})');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportPage(patientChannelId: patient.channelId, patientName: patient.name),
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