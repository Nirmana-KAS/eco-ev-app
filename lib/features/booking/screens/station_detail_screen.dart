// lib/features/booking/screens/station_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eco_ev_app/features/booking/widgets/booking_popup.dart';

class StationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> stationData;
  final String stationId;

  const StationDetailScreen({
    Key? key,
    required this.stationData,
    required this.stationId,
  }) : super(key: key);

  // Helper to launch phone call
  void _launchPhone(String phone) async {
    final Uri url = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // Helper to open maps with address
  void _launchMap(String address) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(stationData['name'] ?? "Station Detail")),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: ListView(
          children: [
            // Main card image
            if (stationData['cardImageUrl'] != null && stationData['cardImageUrl'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  stationData['cardImageUrl'],
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 14),
            // Station logo (if you have a logo)
            if (stationData['logoUrl'] != null && stationData['logoUrl'].toString().isNotEmpty)
              CircleAvatar(
                radius: 32,
                backgroundImage: NetworkImage(stationData['logoUrl']),
                backgroundColor: Colors.grey[200],
              ),
            const SizedBox(height: 10),
            Text(
              stationData['name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            Text(
              stationData['address'] ?? '',
              style: const TextStyle(color: Colors.black54, fontSize: 16),
            ),
            const SizedBox(height: 10),

            // Info row
            Row(
              children: [
                Icon(Icons.phone, color: Colors.green[700], size: 20),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _launchPhone(stationData['contactNumber'] ?? ''),
                  child: Text(
                    stationData['contactNumber'] ?? '',
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.email, color: Colors.green[700], size: 20),
                const SizedBox(width: 4),
                Text(stationData['gmail'] ?? ''),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.bolt, color: Colors.green[700]),
                const SizedBox(width: 6),
                Text('2x Slots: ${stationData['slots2x'] ?? ''}'),
                const SizedBox(width: 14),
                Icon(Icons.flash_on, color: Colors.green[700]),
                const SizedBox(width: 6),
                Text('1x Slots: ${stationData['slots1x'] ?? ''}'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.green[700]),
                const SizedBox(width: 6),
                Text('Hours: ${stationData['openingHours'] ?? ''}'),
                const SizedBox(width: 14),
                Icon(Icons.attach_money, color: Colors.green[700]),
                const SizedBox(width: 6),
                Text('Rs. ${stationData['pricePerHour'] ?? ''}/hour'),
              ],
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.directions, color: Colors.white),
                    label: const Text("Directions"),
                    onPressed: () => _launchMap(stationData['address'] ?? ''),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.phone, color: Colors.white),
                    label: const Text("Call"),
                    onPressed: () => _launchPhone(stationData['contactNumber'] ?? ''),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => Material(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    child: BookingPopup(
                      stationData: stationData,
                      stationId: stationId,
                    ),
                  ),
                );
              },
              child: const Text("Book Slot"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[700],
                minimumSize: const Size(double.infinity, 52),
                textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
