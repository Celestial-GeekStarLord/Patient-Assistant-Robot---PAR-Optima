
PAR Optima 🤖🏥
PAR Optima is a simple hospital robot and app system designed to help doctors, nurses, and patients communicate safely and deliver medicines automatically.
🌟 Key Profiles
1. The Robot 🤖
Located in the hospital ward.
Video Call: One-tap calling to doctors/nurses.
Emergency: Big red button for instant help.
Delivery: Moves medicines and supplies to rooms.
2. The Patient Interface 📱
On the patient's phone.
My Reports: View Reports.
Call Robot: Summon the robot to your bedside.
Meds: Check your medicine schedule.
3. The Staff Interface 👨‍⚕️
For doctors and nurses.
Patient List: See every patient in the ward.
Vitals: Monitor heart rate and temperature live.
Reports: Update patient records and medicine times.
🛠️ How it Works
Flutter: Used for the apps (Android/iOS).
Firebase: Handles real-time data and alerts.
Jitsi: Powers the video calls.
ESP32: Controls the physical robot's movement.
📂 Folder Structure
lib/main.dart: Starts the app.
lib/mode_selector.dart: Choose: Robot, Patient, or Staff.
lib/src/screens/: The three main interfaces.
lib/src/services/: Logic for video calls and database.
🚀 Quick Setup
Install: Run flutter pub get.
Connect: Add your google-services.json (Firebase).
Run: Use flutter run.
👨‍🔬 Features
Safe: Reduces human contact in contagious areas.
Fast: Instant alerts for emergencies.
Easy: Simple UI designed for elderly patients.