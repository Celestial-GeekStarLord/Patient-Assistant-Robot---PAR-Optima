// lib/src/models/patient_record.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PatientRecord {
  final String uid;
  final String customId;
  final String name;
  final String channelId;

  PatientRecord({
    required this.uid,
    required this.customId,
    required this.name,
    required this.channelId,
  });

  // Factory constructor for fetching top-level fields
  factory PatientRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      return PatientRecord(uid: doc.id, customId: 'N/A', name: 'Missing Data', channelId: 'N/A');
    }

    // Extract fields directly from the top-level 'data' map.
    return PatientRecord(
      uid: doc.id,
      customId: data['customId']?.toString() ?? 'N/A',
      name: data['name']?.toString() ?? 'N/A',
      channelId: data['channelId']?.toString() ?? 'N/A',
    );
  }
}