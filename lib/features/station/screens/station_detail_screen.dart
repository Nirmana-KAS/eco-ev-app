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

  @override
  Widget build(BuildContext context) {
    final logoUrl = stationData['logoUrl'] as String?;
    final cardImgUrl = stationData['cardImageUrl'] as String?;
    final name = stationData['name'] ?? '';
    final owner = stationData['owner'] ?? '';
    final address = stationData['address'] ?? '';
    final contact = stationData['contactNumber'] ?? '';
    final gmail = stationData['gmail'] ?? '';
    final slots2x = stationData['slots2x']?.toString() ?? '0';
    final slots1x = stationData['slots1x']?.toString() ?? '0';
    final hours = stationData['openingHours'] ?? '';
    final price = stationData['pricePerHour']?.toString() ?? '';
    final lat = stationData['latitude']?.toString() ?? '';
    final lng = stationData['longitude']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        title: Text(name.isNotEmpty ? name : "Station Details"),
        backgroundColor: const Color(0xFF23272E),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          // Top Card Image
          if (cardImgUrl != null && cardImgUrl.isNotEmpty)
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  child: Image.network(
                    cardImgUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // Shadow over image
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.30),
                      ],
                    ),
                  ),
                ),
                // Logo Overlap
                if (logoUrl != null && logoUrl.isNotEmpty)
                  Positioned(
                    bottom: -34,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.16),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(logoUrl),
                        radius: 38,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 54), // For logo overlap
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 18),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF23272E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  owner,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF30B27C),
                  ),
                ),
                const SizedBox(height: 12),
                _infoRow(Icons.location_on, "Address", address, context),
                const SizedBox(height: 7),
                _infoRow(Icons.email, "Email", gmail, context),
                const SizedBox(height: 7),
                _infoRow(
                  Icons.phone,
                  "Contact",
                  contact,
                  context,
                  trailing: IconButton(
                    icon: Icon(Icons.call, color: Colors.green[700], size: 22),
                    onPressed: () async {
                      final Uri callUri = Uri(
                        scheme: 'tel',
                        path: contact.replaceAll(' ', ''),
                      );
                      print("Launching: $callUri");
                      try {
                        bool launched = await launchUrl(
                          callUri,
                          mode: LaunchMode.externalApplication,
                        );
                        print("Launched: $launched");
                        if (!launched) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not launch dialer!')),
                          );
                        }
                      } catch (e) {
                        print("Launch error: $e");
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                  ),
                ),
                const SizedBox(height: 7),
                _infoRow(Icons.bolt, "2x Speed Slots", slots2x, context),
                const SizedBox(height: 7),
                _infoRow(
                  Icons.bolt_outlined,
                  "1x Speed Slots",
                  slots1x,
                  context,
                ),
                const SizedBox(height: 7),
                _infoRow(Icons.access_time, "Opening Hours", hours, context),
                const SizedBox(height: 7),
                _infoRow(
                  Icons.attach_money,
                  "Price/Hour",
                  "Rs. $price",
                  context,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (lat.isNotEmpty && lng.isNotEmpty) {
                            final url = Uri.parse(
                              "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Location not available")),
                            );
                          }
                        },
                        icon: const Icon(Icons.directions, color: Colors.white),
                        label: const Text("Direction"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          minimumSize: const Size(double.infinity, 48),
                          elevation: 1.5,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await showDialog(
                            context: context,
                            barrierDismissible:
                                false, // user must finish/cancel booking
                            builder:
                                (context) => BookingPopup(
                                  stationId: stationId,
                                  stationData: stationData,
                                ),
                          );
                        },
                        child: const Text("Book Slot"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          minimumSize: const Size(double.infinity, 50),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 34),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
    BuildContext context, {
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.teal[50],
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: Colors.teal[700], size: 21),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Text(
            "$label: $value",
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}
