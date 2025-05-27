// lib/features/station/screens/stations_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// Import your booking popup and station details
import 'package:eco_ev_app/features/booking/widgets/booking_popup.dart';
import 'package:eco_ev_app/features/station/screens/station_detail_screen.dart';

class StationsScreen extends StatelessWidget {
  const StationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stations', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Container(
        color: const Color(0xFFF9F7FA),
        child: Column(
          children: [
            // Search & filter chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SearchBar(),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _Chip(label: "Nearby", selected: true),
                        const SizedBox(width: 10),
                        _Chip(label: "Availability"),
                        const SizedBox(width: 10),
                        _Chip(label: "Newest"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Stations List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('stations')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('No stations found.'));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final docId = docs[i].id;
                      return _StationCard(data: data, docId: docId);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Station Card Widget ---
class _StationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  const _StationCard({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final String name = data['name'] ?? "";
    final String address = data['address'] ?? "";
    final double price = data['pricePerHour']?.toDouble() ?? 0;
    final int slots2x = data['slots2x'] ?? 0;
    final int slots1x = data['slots1x'] ?? 0;
    final int totalSlots = slots2x + slots1x;
    final String logoUrl = data['logoUrl'] ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Logo + Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Station Logo (clickable)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StationDetailScreen(
                        stationData: data,
                        stationId: docId,
                      ),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 38,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: (logoUrl.isNotEmpty)
                      ? NetworkImage(logoUrl)
                      : null,
                  child: (logoUrl.isEmpty)
                      ? const Icon(Icons.ev_station, size: 40, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              // Price and Power Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rs.${price.toStringAsFixed(0)}/hour',
                      style: const TextStyle(
                        color: Color(0xFF22A060),
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.flash_on, color: Colors.teal[700], size: 18),
                        const SizedBox(width: 4),
                        const Text(
                          '2x, 1x Speed',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.ev_station, color: Colors.teal[700], size: 17),
                        Text(
                          '${(data['slots2x'] ?? 0) + (data['slots1x'] ?? 0)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.directions, color: Colors.teal[400], size: 19), // changed icon
                        const SizedBox(width: 3),
                        Flexible(
                          child: InkWell(
                            onTap: () async {
                              String query = Uri.encodeComponent(address);
                              String googleUrl = 'https://www.google.com/maps/search/?api=1&query=$query';
                              if (await canLaunch(googleUrl)) {
                                await launch(googleUrl);
                              }
                            },
                            child: Text(
                              "Direction",
                              style: TextStyle(
                                color: Colors.teal[600],
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 4),
          // Station Name & Address (name is clickable)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StationDetailScreen(
                    stationData: data,
                    stationId: docId,
                  ),
                ),
              );
            },
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 12),
          // Book Now Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.teal.withOpacity(0.09),
                foregroundColor: Colors.teal[700],
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                // Open booking popup
                showDialog(
                  context: context,
                  builder: (context) => BookingPopup(
                    stationData: data,
                    stationId: docId,
                  ),
                );
              },
              child: const Text(
                "Book Now",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Search Bar Widget ---
class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search, size: 22),
        hintText: "Search e-stations, city, etc",
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      // onChanged: (v) { // Add search logic if needed },
    );
  }
}

// --- Filter Chips Widget ---
class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  const _Chip({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE1F5E5) : Colors.grey[100],
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.teal[700] : Colors.grey[600],
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 15,
        ),
      ),
    );
  }
}
