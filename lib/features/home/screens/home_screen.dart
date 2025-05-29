import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:eco_ev_app/features/station/screens/station_search_delegate.dart';
import 'package:eco_ev_app/features/station/screens/station_detail_screen.dart';
import 'package:eco_ev_app/features/booking/widgets/booking_popup.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  String _searchQuery = '';
  Position? _userPosition;
  String _currentAddress = "Loading location...";
  String _userName = "";

  // UI colors
  final Color green = const Color(0xFF138808);
  final Color black = const Color(0xFF23272E);
  final Color offWhite = const Color(0xFFFAFAFA);
  final Color mediumGrey = const Color(0xFFECECEC);
  final Color darkGrey = const Color(0xFF484848);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchUserName();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentAddress = "Location permission denied";
          });
          return;
        }
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _userPosition = position;
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        String area = '';
        if (place.subLocality != null && place.subLocality!.isNotEmpty)
          area += '${place.subLocality}, ';
        if (place.locality != null && place.locality!.isNotEmpty)
          area += '${place.locality}, ';
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty)
          area += '${place.administrativeArea}, ';
        if (place.country != null && place.country!.isNotEmpty)
          area += place.country!;
        area = area.trim();
        if (area.endsWith(',')) area = area.substring(0, area.length - 1);

        setState(() {
          _currentAddress = area.isNotEmpty ? area : "Unknown location";
        });
      } else {
        setState(() {
          _currentAddress = "Unknown location";
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = "Location not found";
      });
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning!';
    } else if (hour < 17) {
      return 'Good Afternoon!';
    } else {
      return 'Good Evening!';
    }
  }

  Future<void> _fetchUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          _userName = doc.data()!['username'] ?? "";
        });
      }
    }
  }

  void _openDirectionWithLatLng(double lat, double lng) async {
    final url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  double? _calculateDistanceKm(double? stationLat, double? stationLng) {
    if (_userPosition == null || stationLat == null || stationLng == null)
      return null;
    final double lat1 = _userPosition!.latitude;
    final double lon1 = _userPosition!.longitude;
    final double lat2 = stationLat;
    final double lon2 = stationLng;
    const double earthRadius = 6371;
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * pi / 180;

  // Checks if station is open now (e.g. "7:00 AM - 10:00 PM")
  bool _isStationOpenNow(Map<String, dynamic> data) {
    try {
      if (data['openingHours'] == null) return false;
      final now = DateTime.now();
      String str = data['openingHours'].toString().replaceAll('\u202F', ' ');
      final parts = str.split('-');
      if (parts.length != 2) return false;

      final open = _parseTime(parts[0].trim());
      final close = _parseTime(parts[1].trim());
      if (open == null || close == null) return false;
      final nowTime = TimeOfDay(hour: now.hour, minute: now.minute);

      bool isOvernight =
          (close.hour < open.hour) ||
          (close.hour == open.hour && close.minute < open.minute);

      if (isOvernight) {
        return (nowTime.hour > open.hour ||
                (nowTime.hour == open.hour && nowTime.minute >= open.minute)) ||
            (nowTime.hour < close.hour ||
                (nowTime.hour == close.hour && nowTime.minute <= close.minute));
      } else {
        return (nowTime.hour > open.hour ||
                (nowTime.hour == open.hour && nowTime.minute >= open.minute)) &&
            (nowTime.hour < close.hour ||
                (nowTime.hour == close.hour && nowTime.minute <= close.minute));
      }
    } catch (e) {
      return false;
    }
  }

  TimeOfDay? _parseTime(String input) {
    try {
      final format = RegExp(r'(\d+):(\d+)\s*([aApP][mM])');
      final match = format.firstMatch(input);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        int minute = int.parse(match.group(2)!);
        final ampm = match.group(3)!.toLowerCase();
        if (ampm == 'pm' && hour != 12) hour += 12;
        if (ampm == 'am' && hour == 12) hour = 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: offWhite,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          children: [
            // GREETING + PROFILE PHOTO
            Padding(
              padding: const EdgeInsets.only(
                top: 24,
                left: 4,
                right: 4,
                bottom: 8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getGreeting(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        if (_userName.isNotEmpty)
                          Text(
                            _userName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  _profilePhoto(context),
                ],
              ),
            ),

            // Location + Notification button
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.location_on, color: green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your Location",
                        style: TextStyle(fontSize: 13, color: darkGrey),
                      ),
                      Text(
                        _currentAddress,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: black,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('notifications')
                          .where(
                            'userId',
                            isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                          )
                          .where('seen', isEqualTo: false)
                          .snapshots(),
                  builder: (context, snapshot) {
                    int unreadCount = 0;
                    if (snapshot.hasData) {
                      unreadCount = snapshot.data!.docs.length;
                    }
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.notifications_none_rounded,
                            color: black,
                            size: 28,
                          ),
                          onPressed: () async {
                            Navigator.pushNamed(context, '/notifications');
                          },
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Center(
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Search Bar (No filter icon)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                await showSearch(
                  context: context,
                  delegate: StationSearchDelegate(),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: mediumGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: darkGrey, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _searchQuery.isEmpty
                            ? "Search e-stations, city, etc"
                            : _searchQuery,
                        style: TextStyle(
                          color: darkGrey,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ---- E-STATIONS NEARBY TITLE ----
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "E-Stations Nearby",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/stations');
                  },
                  child: Text(
                    "See all",
                    style: TextStyle(
                      color: Colors.teal[600],
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // --- Firestore-powered Station Cards ---
            SizedBox(
              height: 260, // <-- INCREASED HEIGHT to fix overflow
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

                  // Only show stations open now and sort by distance
                  docs =
                      docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _isStationOpenNow(data);
                      }).toList();
                  docs.sort((a, b) {
                    final ax = a.data() as Map<String, dynamic>;
                    final bx = b.data() as Map<String, dynamic>;
                    final ad =
                        _calculateDistanceKm(
                          ax['latitude']?.toDouble(),
                          ax['longitude']?.toDouble(),
                        ) ??
                        99999;
                    final bd =
                        _calculateDistanceKm(
                          bx['latitude']?.toDouble(),
                          bx['longitude']?.toDouble(),
                        ) ??
                        99999;
                    return ad.compareTo(bd);
                  });

                  if (docs.isEmpty) {
                    return const Center(child: Text("No open stations found."));
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final stationId = docs[i].id;

                      int slots2x = data['slots2x'] ?? 0;
                      int slots1x = data['slots1x'] ?? 0;
                      int totalSlots = slots2x + slots1x;

                      final lat = data['latitude']?.toDouble();
                      final lng = data['longitude']?.toDouble();

                      return Container(
                        width: 185,
                        margin: const EdgeInsets.only(right: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.13),
                              blurRadius: 18,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(22),
                                topRight: Radius.circular(22),
                              ),
                              child:
                                  data['cardImageUrl'] != null &&
                                          (data['cardImageUrl'] as String)
                                              .isNotEmpty
                                      ? Image.network(
                                        data['cardImageUrl'],
                                        height: 95,
                                        width: 185,
                                        fit: BoxFit.cover,
                                      )
                                      : Container(
                                        height: 95,
                                        width: 185,
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.ev_station,
                                          size: 38,
                                          color: Colors.grey,
                                        ),
                                      ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Text(
                                'Rs.${data['pricePerHour']}/hour',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF30B27C),
                                ),
                              ),
                            ),
                            // --- Slot counts & icons row
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 1,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.flash_on,
                                    color: Color(0xFFFFA800),
                                    size: 15,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '2x: ',
                                    style: TextStyle(
                                      color: Color(0xFFFFA800),
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '$slots2x',
                                    style: TextStyle(
                                      color: Color(0xFFFFA800),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.flash_on,
                                    color: Color(0xFFFFA800),
                                    size: 15,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '1x: ',
                                    style: TextStyle(
                                      color: Color(0xFFFFA800),
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '$slots1x',
                                    style: TextStyle(
                                      color: Color(0xFFFFA800),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(
                                    Icons.ev_station,
                                    color: Colors.green[600],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '$totalSlots',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // --- Address and Direction (Direction moved here!)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 1,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.teal[400],
                                    size: 14,
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      data['address'] ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // DIRECTION BUTTON in red-marked place!
                                  IconButton(
                                    icon: Icon(
                                      Icons.directions,
                                      color: Colors.teal[700],
                                      size: 20,
                                    ),
                                    onPressed:
                                        (lat != null && lng != null)
                                            ? () => _openDirectionWithLatLng(
                                              lat,
                                              lng,
                                            )
                                            : null,
                                    tooltip: "Direction",
                                  ),
                                ],
                              ),
                            ),
                            // --- Book Now Button
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                2,
                                14,
                                10,
                              ), // 8 -> 2 to reduce gap above Book Now
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF30B27C),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    elevation: 2,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                  ),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: const Color.fromARGB(
                                        255,
                                        44,
                                        43,
                                        43,
                                      ),
                                      builder:
                                          (_) => Material(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(22),
                                                ),
                                            child: BookingPopup(
                                              stationData: data,
                                              stationId: stationId,
                                            ),
                                          ),
                                    );
                                  },
                                  child: const Text(
                                    'Book Now',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Recommendations Title Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Our Recommendations",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/stations');
                  },
                  child: Text(
                    "See all",
                    style: TextStyle(
                      color: Colors.teal[600],
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Recommendations Card List (vertically scrollable)
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('stations')
                      .orderBy('createdAt', descending: false) // oldest first
                      .limit(3)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final recommendedStations = snapshot.data!.docs;
                return Column(
                  children: List.generate(recommendedStations.length, (index) {
                    final station = recommendedStations[index];
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: 12.0,
                      ), // Prevent overflow
                      child: RecommendationsCard(
                        data: station.data() as Map<String, dynamic>,
                        stationId: station.id,
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // User Profile Photo Widget
  Widget _profilePhoto(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !(snapshot.data!.data() is Map)) {
          return _defaultAvatar();
        }
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final photoUrl = data['photoUrl'] as String?;
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/profile');
          },
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey[300],
            backgroundImage:
                (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : const AssetImage('assets/profile_placeholder.png')
                        as ImageProvider,
          ),
        );
      },
    );
  }

  Widget _defaultAvatar() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/profile');
      },
      child: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.grey[300],
        backgroundImage: const AssetImage('assets/profile_placeholder.png'),
      ),
    );
  }
}

// Recommendations Card Widget
class RecommendationsCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String stationId;

  const RecommendationsCard({
    super.key,
    required this.data,
    required this.stationId,
  });

  bool isOpenNow(String openingHours) {
    try {
      if (openingHours.isEmpty) return false;
      final now = DateTime.now();
      final parts = openingHours.replaceAll('\u202F', ' ').split('-');
      if (parts.length != 2) return false;
      final format = DateFormat('h:mm a');
      final open = format.parse(parts[0].trim());
      final close = format.parse(parts[1].trim());
      final nowTime = TimeOfDay(hour: now.hour, minute: now.minute);
      final openTime = TimeOfDay(hour: open.hour, minute: open.minute);
      final closeTime = TimeOfDay(hour: close.hour, minute: close.minute);

      if ((closeTime.hour < openTime.hour) ||
          (closeTime.hour == openTime.hour &&
              closeTime.minute < openTime.minute)) {
        return (nowTime.hour > openTime.hour ||
                (nowTime.hour == openTime.hour &&
                    nowTime.minute >= openTime.minute)) ||
            (nowTime.hour < closeTime.hour ||
                (nowTime.hour == closeTime.hour &&
                    nowTime.minute <= closeTime.minute));
      } else {
        return (nowTime.hour > openTime.hour ||
                (nowTime.hour == openTime.hour &&
                    nowTime.minute >= openTime.minute)) &&
            (nowTime.hour < closeTime.hour ||
                (nowTime.hour == closeTime.hour &&
                    nowTime.minute <= closeTime.minute));
      }
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = data['name'] ?? '';
    final String address = data['address'] ?? '';
    final double latitude = (data['latitude'] as num?)?.toDouble() ?? 0.0;
    final double longitude = (data['longitude'] as num?)?.toDouble() ?? 0.0;
    final String openingHours = data['openingHours'] ?? '';
    final bool open = isOpenNow(openingHours);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => StationDetailScreen(
                  stationData: data,
                  stationId: stationId,
                ),
          ),
        );
      },
      child: Container(
        width: 320,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Station image with top-right star badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                  child:
                      data['cardImageUrl'] != null &&
                              (data['cardImageUrl'] as String).isNotEmpty
                          ? Image.network(
                            data['cardImageUrl'],
                            height: 120,
                            width: 320,
                            fit: BoxFit.cover,
                          )
                          : Container(
                            height: 120,
                            width: 320,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.ev_station,
                              size: 38,
                              color: Colors.grey,
                            ),
                          ),
                ),
                Positioned(
                  top: 13,
                  right: 13,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.star, color: Colors.amber, size: 32),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.teal[400],
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 2),
                      InkWell(
                        onTap: () async {
                          final url = Uri.parse(
                            "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude",
                          );
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },
                        child: Icon(
                          Icons.directions,
                          color: Colors.teal[600],
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        open ? Icons.check_circle : Icons.cancel,
                        color: open ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        open ? 'Open now' : 'Closed',
                        style: TextStyle(
                          color: open ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 38),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(22),
                            ),
                          ),
                          builder:
                              (_) => BookingPopup(
                                stationData: data,
                                stationId: stationId,
                              ),
                        );
                      },
                      child: const Text(
                        'Book Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
