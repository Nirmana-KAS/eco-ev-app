import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isAdmin = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      print("Current user UID: ${user.uid}");
      print("Fetched Firestore doc: ${doc.data()}");
      final data = doc.data();
      if (data != null && data['role'] == 'admin') {
        setState(() {
          _isAdmin = true;
        });
      }
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Access Denied.\nYou are not an admin.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/welcome',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stations').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No charging stations found."));
          }
          final docs = snapshot.data!.docs;
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.ev_station, color: Colors.green),
                title: Text(
                  data['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Location: ${data['address'] ?? ''}\nPorts: ${data['availablePorts'] ?? 0}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/edit-station',
                          arguments:
                              docs[index]
                                  .id, // <-- Pass the Firestore document ID
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder:
                              (ctx) => AlertDialog(
                                title: const Text('Delete Station'),
                                content: const Text(
                                  'Are you sure you want to delete this station?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                        );
                        if (confirm == true) {
                          await FirebaseFirestore.instance
                              .collection('stations')
                              .doc(docs[index].id)
                              .delete();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Station deleted')),
                          );
                        }
                      },
                    ),
                  ],
                ),
                isThreeLine: true,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: "Add Station",
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.pushNamed(context, '/add-station');
        },
      ),
    );
  }
}
