import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: Colors.green,
              child: Icon(Icons.person, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              user?.displayName ?? 'No Name',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? 'No Email',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Log Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/welcome', (route) => false);
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
