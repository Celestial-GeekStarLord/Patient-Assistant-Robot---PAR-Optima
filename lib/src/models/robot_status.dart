class RobotStatus {
  final String location;
  final int battery;
  final String task;

  RobotStatus({required this.location, required this.battery, required this.task});

  factory RobotStatus.fromMap(Map<dynamic, dynamic> data) {
    return RobotStatus(
      location: data['location'] ?? "Station",
      battery: data['battery'] ?? 0,
      task: data['task'] ?? "Idle",
    );
  }
}