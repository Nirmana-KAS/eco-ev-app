// lib/features/home/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:eco_ev_app/features/station/screens/station_search_delegate.dart';
import 'package:eco_ev_app/features/station/screens/station_detail_screen.dart';
import 'package:eco_ev_app/features/booking/widgets/booking_popup.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  String _searchQuery = '';
  final Color green = const Color(0xFF138808);
  final Color black = const Color(0xFF23272E);
  final Color offWhite = const Color(0xFFFAFAFA);
  final Color mediumGrey = const Color(0xFFECECEC);
  final Color darkGrey = const Color(0xFF484848);

  String _currentAddress = "Loading location...";
  String _userName = "";
  Position? _userPosition;

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
          _userPosition = position;
        });
      } else {
        setState(() {
          _currentAddress = "Unknown location";
          _userPosition = position;
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

  void _openDirectionWithLatLng(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // Check if a station is open now based on openingHours string, e.g. "7:00 AM - 10:00 PM"
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

      if ((closeTime.hour < openTime.hour) ||
          (closeTime.hour == openTime.hour &&
              closeTime.minute < openTime.minute)) {
        // Overnight opening
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

  double? _stationDistance(Map<String, dynamic> data) {
    try {
      if (_userPosition == null ||
          data['latitude'] == null ||
          data['longitude'] == null)
        return null;
      final lat =
          data['latitude'] is double
              ? data['latitude']
              : double.tryParse(data['latitude'].toString());
      final lng =
          data['longitude'] is double
              ? data['longitude']
              : double.tryParse(data['longitude'].toString());
      if (lat == null || lng == null) return null;
      return Geolocator.distanceBetween(
            _userPosition!.latitude,
            _userPosition!.longitude,
            lat,
            lng,
          ) /
          1000.0;
    } catch (_) {
      return null;
    }
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
              height: 240,
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
                  var docs = snapshot.data!.docs;

                  // Filter for open now & sort by distance
                  List<QueryDocumentSnapshot> filteredDocs =
                      docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _isStationOpenNow(data);
                      }).toList();

                  // Sort by distance
                  if (_userPosition != null) {
                    filteredDocs.sort((a, b) {
                      final ad =
                          _stationDistance(a.data() as Map<String, dynamic>) ??
                          double.infinity;
                      final bd =
                          _stationDistance(b.data() as Map<String, dynamic>) ??
                          double.infinity;
                      return ad.compareTo(bd);
                    });
                  }

                  if (filteredDocs.isEmpty) {
                    return const Center(
                      child: Text("No open stations found nearby."),
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, i) {
                      final data =
                          filteredDocs[i].data() as Map<String, dynamic>;
                      final stationId = filteredDocs[i].id;

                      int slots2x = data['slots2x'] ?? 0;
                      int slots1x = data['slots1x'] ?? 0;
                      int totalSlots = slots2x + slots1x;

                      double? lat =
                          data['latitude'] is double
                              ? data['latitude']
                              : double.tryParse(
                                data['latitude']?.toString() ?? '',
                              );
                      double? lng =
                          data['longitude'] is double
                              ? data['longitude']
                              : double.tryParse(
                                data['longitude']?.toString() ?? '',
                              );
                      double? distanceKm = _stationDistance(data);

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
                                  if (distanceKm != null && distanceKm < 99999)
                                    Text(
                                      "${distanceKm.toStringAsFixed(1)} km",
                                      style: TextStyle(
                                        color: Colors.teal[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 1,
                              ),
                              child: Row(
                                children: [
                                  TextButton(
                                    onPressed:
                                        (lat != null && lng != null)
                                            ? () => _openDirectionWithLatLng(
                                              lat,
                                              lng,
                                            )
                                            : null,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(50, 22),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      "Direction",
                                      style: TextStyle(
                                        color: Colors.teal[700],
                                        fontSize: 12,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
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
            const SizedBox(height: 12),

            // Recommendations (you can further upgrade to use Firestore here)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Our Recommendations",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: black,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    "See all",
                    style: TextStyle(
                      color: green,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _recommendCard(image: 'assets/charging3.jpg', isTop: true),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // ADMIN DASHBOARD BUTTON
            // FutureBuilder<DocumentSnapshot>(
            //   future:
            //       FirebaseFirestore.instance
            //           .collection('users')
            //           .doc(FirebaseAuth.instance.currentUser!.uid)
            //           .get(),
            //   builder: (context, snapshot) {
            //     if (!snapshot.hasData) return const SizedBox();
            //     final data = snapshot.data!.data() as Map<String, dynamic>?;
            //     if (data != null && data['role'] == 'admin') {
            //       return Padding(
            //         padding: const EdgeInsets.only(bottom: 12.0),
            //         child: ElevatedButton.icon(
            //           icon: const Icon(Icons.admin_panel_settings),
            //           label: const Text("Admin Dashboard"),
            //           onPressed: () => Navigator.pushNamed(context, '/admin'),
            //           style: ElevatedButton.styleFrom(
            //             backgroundColor: const Color(0xFF30B27C),
            //           ),
            //         ),
            //       );
            //     }
            //     return const SizedBox();
            //   },
            // ),
          ],
        ),
      ),

      // BOTTOM NAV BAR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (idx) {
          setState(() => _selectedTab = idx);
          if (idx == 1) {
            Navigator.pushNamed(context, '/stations');
          } else if (idx == 2) {
            Navigator.pushNamed(context, '/booking');
          } else if (idx == 3) {
            Navigator.pushNamed(context, '/profile');
          }
          // Home (idx == 0) does nothing because you're already on Home.
        },
        selectedItemColor: green,
        unselectedItemColor: darkGrey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.ev_station_rounded),
            label: "Stations",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_rounded),
            label: "Booking",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  // Recommendation Card Widget
  Widget _recommendCard({required String image, required bool isTop}) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: mediumGrey.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              image,
              height: 150,
              width: 320,
              fit: BoxFit.cover,
            ),
          ),
          if (isTop)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "Top",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 10,
            right: 10,
            child: InkWell(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.favorite_border, color: green, size: 20),
              ),
            ),
          ),
        ],
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
