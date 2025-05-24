import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color green = const Color(0xFF138808);
    final Color deepPurple = Colors.deepPurple;
    final Color offWhite = const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: offWhite,
      appBar: AppBar(
        title: const Text('About Us'),
        backgroundColor: deepPurple,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
        children: [
          // --- App Logo ---
          Center(
            child: CircleAvatar(
              radius: 52,
              backgroundColor: green.withOpacity(0.10),
              backgroundImage: const AssetImage('assets/app_logo.png'),
              // If logo not present, fallback:
              // child: Icon(Icons.ev_station, size: 60, color: green),
            ),
          ),
          const SizedBox(height: 24),

          // --- Company Name ---
          Center(
            child: Text(
              "ECO EV Solutions Pvt Ltd",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: deepPurple),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              "Empowering Sri Lanka's EV Future",
              style: TextStyle(fontSize: 16, color: green, fontWeight: FontWeight.w500),
            ),
          ),

          const Divider(height: 36, thickness: 1.2),

          // --- App Info ---
          Text(
            "Application Info",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: green),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.verified, color: deepPurple, size: 18),
              const SizedBox(width: 8),
              const Text("App: ECO EV App", style: TextStyle(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.emoji_objects, color: deepPurple, size: 18),
              const SizedBox(width: 8),
              const Text("Version: 1.0.0", style: TextStyle(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.place, color: green, size: 18),
              const SizedBox(width: 8),
              const Text("University: NSBM Green University Town", style: TextStyle(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 20),

          // --- Technologies Used ---
          Text(
            "Technologies Used",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: deepPurple),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _chipTech('Flutter', Icons.flutter_dash, Colors.blue),
              _chipTech('Firebase', Icons.cloud, Colors.orange),
              _chipTech('Google Maps API', Icons.map, Colors.red),
              _chipTech('Dart', Icons.code, Colors.teal),
              _chipTech('Cloud Firestore', Icons.storage, Colors.deepPurple),
            ],
          ),
          const SizedBox(height: 24),

          // --- Developers ---
          Text(
            "Development Team",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: green),
          ),
          const SizedBox(height: 12),
          _devTile("Shehan Nirmana", "Lead Developer", Icons.person_pin, deepPurple),
          _devTile("Nethmina Kavinda", "Co-Developer", Icons.person_pin_circle, green),
          _devTile("Sakunu Sirimanna", "Co-Developer", Icons.person_pin_rounded, Colors.blueGrey),
          const SizedBox(height: 36),

          // --- Contact Info ---
          Center(
            child: Column(
              children: [
                const Text("Contact Us", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.email, color: deepPurple, size: 18),
                    const SizedBox(width: 7),
                    const Text("info@ecoev.lk", style: TextStyle(fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone, color: green, size: 18),
                    const SizedBox(width: 7),
                    const Text("+94 11 123 4567", style: TextStyle(fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "© 2025 ECO EV App | All rights reserved",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Tech Chip Widget ---
  Widget _chipTech(String name, IconData icon, Color color) {
    return Chip(
      avatar: Icon(icon, color: color, size: 20),
      label: Text(name, style: TextStyle(color: color)),
      backgroundColor: color.withOpacity(0.08),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // --- Developer Tile Widget ---
  Widget _devTile(String name, String role, IconData icon, Color color) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 0, right: 0),
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.16),
        child: Icon(icon, color: color),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(role),
    );
  }
}
