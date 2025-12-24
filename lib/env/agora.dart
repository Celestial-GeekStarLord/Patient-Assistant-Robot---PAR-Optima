// lib/env/agora.dart

/// 🛑 IMPORTANT: This file should be added to your .gitignore to prevent
/// private keys from being accidentally committed to source control.

class AgoraConfig {
  // 1. Agora App ID (Required to initialize the RtcEngine)
  // Get this from your Agora Console: https://console.agora.io/
  static const String agoraAppId = '9e259b71b48f4c159d26069f597521f8';

  // 2. Token Server URL
  // This is the endpoint of YOUR SECURE BACKEND SERVER that generates
  // the dynamic RTC token for authentication.
  // The client app should NEVER contain the Agora App Certificate.
  static const String agoraTokenFunctionName =
      'generateAgoraRtcToken'; // NOTE: For an Android emulator to access a local host server,
  // you might need to use 'http://10.0.2.2:8080/rtc/'
}
