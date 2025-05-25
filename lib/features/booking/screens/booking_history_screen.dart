// lib/features/booking/screens/booking_history_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({Key? key}) : super(key: key);

  String formatDateTime(dynamic timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp is DateTime
        ? timestamp
        : (timestamp is Timestamp ? timestamp.toDate() : null);
    if (dt == null) return '';
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text("My Bookings")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("No bookings yet."));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal[100],
                    child: Icon(Icons.ev_station, color: Colors.teal[700]),
                  ),
                  title: Text(
                    data['stationName'] ?? 'Unknown Station',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Date: ${formatDateTime(data['startTime'])} - ${formatDateTime(data['endTime'])}",
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        "Plate: ${data['plateNumber'] ?? ''}",
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (data['slotType'] != null)
                        Text(
                          "Slot: ${data['slotType'] == '2x' ? '2x Speed' : '1x Speed'}",
                          style: const TextStyle(fontSize: 13),
                        ),
                      if (data['status'] != null)
                        Text(
                          "Status: ${data['status']}",
                          style: TextStyle(
                            fontSize: 12,
                            color: data['status'] == 'booked'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                    ],
                  ),
                  trailing: Text(
                    "Rs. ${data['price'] ?? '0'}",
                    style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  // Optional: tap to show full booking details
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(data['stationName'] ?? 'Booking Detail'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Address: ${data['address'] ?? '-'}"),
                            Text(
                              "Time: ${formatDateTime(data['startTime'])} - ${formatDateTime(data['endTime'])}",
                            ),
                            Text("Plate: ${data['plateNumber'] ?? '-'}"),
                            Text(
                                "Vehicle: ${data['vehicleType'] ?? '-'}"),
                            Text(
                                "Slot Type: ${data['slotType'] == '2x' ? '2x Speed' : '1x Speed'}"),
                            Text(
                                "Status: ${data['status'] ?? '-'}"),
                            Text(
                                "Price: Rs. ${data['price'] ?? '0'}"),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Close"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
