import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_ev_app/features/station/screens/station_detail_screen.dart';

class StationSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  String get searchFieldLabel => "Search e-stations, city, etc";

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => _buildSuggestionList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSuggestionList(context);

  Widget _buildSuggestionList(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text("Type to search stations..."));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stations')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final address = (data['address'] ?? '').toString().toLowerCase();
          final city = (data['city'] ?? '').toString().toLowerCase();
          final district = (data['district'] ?? '').toString().toLowerCase();
          final q = query.toLowerCase();
          return name.contains(q) || address.contains(q) || city.contains(q) || district.contains(q);
        }).toList();

        if (docs.isEmpty) {
          return const Center(child: Text("No stations found"));
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? '';
            final address = data['address'] ?? '';
            final city = data['city'] ?? '';

            return ListTile(
              leading: Icon(Icons.location_on_outlined, color: Colors.grey[700]),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(city.isNotEmpty ? '$address, $city' : address),
              onTap: () {
                // After tap: close search bar, then navigate to details.
                close(context, '');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StationDetailScreen(
                      stationData: data,
                      stationId: doc.id,
                    ),
                  ),
                );
              },
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
            );
          },
        );
      },
    );
  }
}
