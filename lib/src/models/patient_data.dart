class PatientData {
  final String name;
  final String room;
  final int heartRate;
  final double temperature;
  final int spo2;
  final bool isEmergency;

  PatientData({
    required this.name,
    required this.room,
    required this.heartRate,
    required this.temperature,
    required this.spo2,
    required this.isEmergency,
  });

  factory PatientData.fromMap(Map<dynamic, dynamic> data) {
    return PatientData(
      name: data['name'] ?? "Unknown",
      room: data['room'] ?? "N/A",
      heartRate: data['heartRate'] ?? 0,
      temperature: (data['temperature'] ?? 0.0).toDouble(),
      spo2: data['spo2'] ?? 0,
      isEmergency: data['isEmergency'] ?? false,
    );
  }
}