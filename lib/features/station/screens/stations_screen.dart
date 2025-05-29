import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:eco_ev_app/features/booking/widgets/booking_popup.dart';
import 'package:eco_ev_app/features/station/screens/station_detail_screen.dart';
import 'package:eco_ev_app/features/station/screens/station_search_delegate.dart';

class StationsScreen extends StatefulWidget {
  const StationsScreen({super.key});

  @override
  State<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends State<StationsScreen> {
  int _selectedChip = 0; // 0:Nearby 1:Availability 2:Newest
  Position? _userPosition;
  List<QueryDocumentSnapshot>? _docsCache; // cache so location sort is smooth

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
        setState(() {
          _userPosition = pos;
        });
      }
    } catch (e) {
      // ignore location if error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stations',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                  _searchBar(context),
                  const SizedBox(height: 12),
                  _FilterChips(
                    selected: _selectedChip,
                    onChanged: (i) => setState(() => _selectedChip = i),
                  ),
                ],
              ),
            ),
            // Stations List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('stations')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
                  _docsCache = docs;

                  // --- Sorting/Filtering ---
                  if (_selectedChip == 0 && _userPosition != null) {
                    // Nearby: Sort by distance
                    docs = [...docs];
                    docs.sort((a, b) {
                      final ax = a.data() as Map<String, dynamic>;
                      final bx = b.data() as Map<String, dynamic>;
                      double ad = _distanceFromUser(ax);
                      double bd = _distanceFromUser(bx);
                      return ad.compareTo(bd);
                    });
                  } else if (_selectedChip == 1) {
                    // Availability: Show only open stations
                    docs =
                        docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return _isStationOpenNow(data);
                        }).toList();
                  } // Newest: Already sorted

                  if (docs.isEmpty) {
                    return const Center(child: Text('No stations found.'));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final docId = docs[i].id;
                      final double? distKm =
                          _userPosition != null
                              ? _distanceFromUser(data)
                              : null;
                      return _StationCard(
                        data: data,
                        docId: docId,
                        distanceKm: distKm,
                      );
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

  // --- SEARCH BAR (like Home screen) ---
  Widget _searchBar(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await showSearch(context: context, delegate: StationSearchDelegate());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey[600], size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Search e-stations, city, etc",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Calculate distance in km from user position to station ---
  double _distanceFromUser(Map<String, dynamic> data) {
    try {
      if (_userPosition == null ||
          data['latitude'] == null ||
          data['longitude'] == null)
        return 999999;
      final lat =
          data['latitude'] is double
              ? data['latitude']
              : double.tryParse(data['latitude'].toString());
      final lng =
          data['longitude'] is double
              ? data['longitude']
              : double.tryParse(data['longitude'].toString());
      if (lat == null || lng == null) return 999999;
      return Geolocator.distanceBetween(
            _userPosition!.latitude,
            _userPosition!.longitude,
            lat,
            lng,
          ) /
          1000.0; // km
    } catch (_) {
      return 999999;
    }
  }

  // --- Check if station open now (24h format) ---
  bool _isStationOpenNow(Map<String, dynamic> data) {
    try {
      if (data['openingHours'] == null) return false;
      final now = DateTime.now();
      String str = data['openingHours'].toString().replaceAll('\u202F', ' ');
      final parts = str.split('-');
      if (parts.length != 2) return false;
      final format = DateFormat('h:mm a');
      String openStr = parts[0].trim();
      String closeStr = parts[1].trim();
      openStr = openStr.replaceAll('\u202F', ' ');
      closeStr = closeStr.replaceAll('\u202F', ' ');
      final open = format.parse(openStr);
      final close = format.parse(closeStr);
      final nowTime = TimeOfDay(hour: now.hour, minute: now.minute);
      final openTime = TimeOfDay(hour: open.hour, minute: open.minute);
      final closeTime = TimeOfDay(hour: close.hour, minute: close.minute);

      // Handle overnight opening (e.g. 8:00 PM - 2:00 AM)
      if ((closeTime.hour < openTime.hour) ||
          (closeTime.hour == openTime.hour &&
              closeTime.minute < openTime.minute)) {
        // Overnight
        return (nowTime.hour > openTime.hour ||
                (nowTime.hour == openTime.hour &&
                    nowTime.minute >= openTime.minute)) ||
            (nowTime.hour < closeTime.hour ||
                (nowTime.hour == closeTime.hour &&
                    nowTime.minute <= closeTime.minute));
      } else {
        // Normal daytime
        return (nowTime.hour > openTime.hour ||
                (nowTime.hour == openTime.hour &&
                    nowTime.minute >= openTime.minute)) &&
            (nowTime.hour < closeTime.hour ||
                (nowTime.hour == closeTime.hour &&
                    nowTime.minute <= closeTime.minute));
      }
    } catch (e) {
      return false;
    }
  }
}

// --- Station Card Widget ---
class _StationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final double? distanceKm;
  const _StationCard({
    required this.data,
    required this.docId,
    this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    final String name = data['name'] ?? "";
    final String address = data['address'] ?? "";
    final double price = data['pricePerHour']?.toDouble() ?? 0;
    final int slots2x = data['slots2x'] ?? 0;
    final int slots1x = data['slots1x'] ?? 0;
    final int totalSlots = slots2x + slots1x;
    final String logoUrl = data['logoUrl'] ?? '';
    final double? lat =
        data['latitude'] is double
            ? data['latitude']
            : double.tryParse(data['latitude']?.toString() ?? '');
    final double? lng =
        data['longitude'] is double
            ? data['longitude']
            : double.tryParse(data['longitude']?.toString() ?? '');

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
                      builder:
                          (_) => StationDetailScreen(
                            stationData: data,
                            stationId: docId,
                          ),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 38,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      (logoUrl.isNotEmpty) ? NetworkImage(logoUrl) : null,
                  child:
                      (logoUrl.isEmpty)
                          ? const Icon(
                            Icons.ev_station,
                            size: 40,
                            color: Colors.grey,
                          )
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
                        fontSize: 20,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.flash_on, color: Colors.teal[700], size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '2x, 1x Speed',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.ev_station,
                          color: Colors.teal[700],
                          size: 17,
                        ),
                        Text(
                          '$totalSlots',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions,
                          color: Colors.teal[400],
                          size: 19,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: InkWell(
                            onTap: () async {
                              // --------- OPEN GOOGLE MAPS BY COORDINATES ----------
                              if (lat != null && lng != null) {
                                final url = Uri.parse(
                                  'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                                );
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Could not open Maps!'),
                                    ),
                                  );
                                }
                              } else if (address.isNotEmpty) {
                                // fallback if coords missing
                                String query = Uri.encodeComponent(address);
                                String googleUrl =
                                    'https://www.google.com/maps/search/?api=1&query=$query';
                                if (await canLaunchUrl(Uri.parse(googleUrl))) {
                                  await launchUrl(Uri.parse(googleUrl));
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Location not available'),
                                  ),
                                );
                              }
                            },
                            child: Row(
                              children: [
                                const Text(
                                  "Direction",
                                  style: TextStyle(
                                    color: Color(0xFF0BA678),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                    decoration: TextDecoration.underline,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (distanceKm != null && distanceKm! < 99999)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 7),
                                    child: Text(
                                      "(${distanceKm!.toStringAsFixed(1)} km)",
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
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
                  builder:
                      (_) => StationDetailScreen(
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  
                ),
              ),
              onPressed: () {
                // Open booking popup
                showDialog(
                  context: context,
                  builder:
                      (context) =>
                          BookingPopup(stationData: data, stationId: docId),
                );
              },
              child: const Text(
                "Book Now",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
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

// --- Filter Chips Widget ---
class _FilterChips extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _FilterChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final chips = ["Nearby", "Availability", "Newest"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(chips.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      selected == i
                          ? const Color(0xFFE1F5E5)
                          : Colors.grey[100],
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Text(
                  chips[i],
                  style: TextStyle(
                    color: selected == i ? Colors.teal[700] : Colors.grey[600],
                    fontWeight:
                        selected == i ? FontWeight.bold : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
