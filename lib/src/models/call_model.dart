// lib/src/models/call_model.dart

class CallModel {
  final String callerId;
  final String callerName;
  final String receiverId;
  final String receiverName;
  final String channelId; // Agora channel name (e.g., room_401_call)
  final String status;    // 'ringing', 'accepted', 'rejected', 'ended'
  final bool isRobot;     // True if the caller is the Robot/Staff system

  CallModel({
    required this.callerId,
    required this.callerName,
    required this.receiverId,
    required this.receiverName,
    required this.channelId,
    required this.status,
    required this.isRobot,
  });

  // Factory constructor to create a CallModel from a Firebase RTDB map
  factory CallModel.fromMap(Map<String, dynamic> map) {
    return CallModel(
      callerId: map['callerId'] ?? '',
      callerName: map['callerName'] ?? '',
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      channelId: map['channelId'] ?? '',
      status: map['status'] ?? 'ringing',
      isRobot: map['isRobot'] ?? false,
    );
  }

  // Convert the CallModel to a map for writing to Firebase RTDB
  Map<String, dynamic> toMap() {
    return {
      'callerId': callerId,
      'callerName': callerName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'channelId': channelId,
      'status': status,
      'isRobot': isRobot,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  // Helper method to create a new instance with updated properties
  CallModel copyWith({
    String? callerId,
    String? callerName,
    String? receiverId,
    String? receiverName,
    String? channelId,
    String? status,
    bool? isRobot,
  }) {
    return CallModel(
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      channelId: channelId ?? this.channelId,
      status: status ?? this.status,
      isRobot: isRobot ?? this.isRobot,
    );
  }
}