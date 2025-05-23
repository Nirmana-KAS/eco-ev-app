import 'package:flutter/gestures.dart'; // Only needed once at the top
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  int _selectedChip = 0;
  final List<String> chips = ["Nearby", "Top Rated", "Popular", "Availability"];

  // Define your colors here for easy updates
  final Color orange = const Color(0xFFFFA800);
  final Color green = const Color(0xFF138808);
  final Color ecoGreen = const Color(0xFF61B15A);
  final Color black = const Color(0xFF23272E);
  final Color offWhite = const Color(0xFFFAFAFA);
  final Color mediumGrey = const Color(0xFFECECEC);
  final Color darkGrey = const Color(0xFF484848);

  String _currentAddress = "Loading location...";
  String _userName = "";

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
        // Removed: if (place.name != null && place.name!.isNotEmpty) area += '${place.name}, ';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: offWhite,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          children: [
            // GREETING MESSAGE
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 12.0),
              child: Text(
                '${getGreeting()}${_userName.isNotEmpty ? ' $_userName' : ''}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: black,
                ),
              ),
            ),

            // HEADER ROW: Location and Notifications
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, color: green, size: 20),
                const SizedBox(width: 8),
                // The Expanded widget ensures the text wraps and never overflows!
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
                          overflow:
                              TextOverflow
                                  .ellipsis, // Optional: adds "..." if too long
                        ),
                        maxLines: 2, // Wraps to 2 lines if needed
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.notifications_none_rounded,
                    color: black,
                    size: 28,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 8),

            // SEARCH BAR & FILTER
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
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
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Search e-stations, city, etc",
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: darkGrey,
                                fontSize: 15,
                              ),
                              isDense: true,
                            ),
                            style: TextStyle(fontSize: 15, color: black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: mediumGrey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.tune_rounded, color: green),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // TAB BAR (Chips)
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: chips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final selected = i == _selectedChip;
                  return ChoiceChip(
                    label: Text(chips[i]),
                    selected: selected,
                    selectedColor: green.withOpacity(0.15),
                    backgroundColor: mediumGrey,
                    labelStyle: TextStyle(
                      color: selected ? green : black,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedChip = i);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // SECTION: E-Stations Nearby
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "E-Stations Nearby",
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
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _stationCard(
                    image: 'assets/charging1.jpg',
                    isTop: true,
                    price: 'Rs.500/hour',
                    speed: '2x Speed',
                    slots: '10',
                    power: '700 kW',
                    address: 'High-Level Road, Nugegoda',
                  ),
                  _stationCard(
                    image: 'assets/charging2.jpg',
                    isTop: true,
                    price: 'Rs.500/hour',
                    speed: '2x Speed',
                    slots: '8',
                    power: '500 kW',
                    address: 'High-Level Road, Kandy',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // SECTION: Recommendations
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

            // ADMIN DASHBOARD BUTTON (conditionally visible)
            FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data != null && data['role'] == 'admin') {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.admin_panel_settings),
                      label: const Text("Admin Dashboard"),
                      onPressed: () => Navigator.pushNamed(context, '/admin'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),

            // === DEBUG BUTTON: Remove after checking! ===
            // ElevatedButton(
            //   onPressed: () async {
            //     final user = FirebaseAuth.instance.currentUser;
            //     if (user != null) {
            //       final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
            //       print("Current user UID: ${user.uid}");
            //       print("Firestore user doc: ${doc.data()}");
            //       ScaffoldMessenger.of(context).showSnackBar(
            //         SnackBar(content: Text("UID: ${user.uid}\nRole: ${doc.data()?['role']}")),
            //       );
            //     }
            //   },
            //   child: const Text("Check Firestore UID/Role"),
            // ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text.rich(
                  TextSpan(
                    text: "Don’t have an account? ",
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF484848),
                    ),
                    children: [
                      TextSpan(
                        text: "Register Now",
                        style: const TextStyle(
                          color: Color(0xFF138808),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
                        recognizer:
                            TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/sign-up',
                                );
                              },
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          ],
          // End of ListView children
        ),
      ),

      // BOTTOM NAV BAR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (idx) {
          setState(() => _selectedTab = idx);
          if (idx == 3) {
            // Profile tab
            Navigator.pushNamed(context, '/profile');
          }
          // You can add navigation for other tabs here if needed
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

  // E-Station Card Widget
  Widget _stationCard({
    required String image,
    required bool isTop,
    required String price,
    required String speed,
    required String slots,
    required String power,
    required String address,
  }) {
    return Container(
      width: 270,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + Top badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
                child: Image(
                  image:
                      (image != null && image.isNotEmpty)
                          ? NetworkImage(image)
                          : const AssetImage('assets/charging_placeholder.jpg')
                              as ImageProvider,
                  height: 90,
                  width: 270,
                  fit: BoxFit.cover,
                ),
              ),
              if (isTop)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              price,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: green,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.flash_on, size: 16, color: orange),
                Text(
                  ' $speed  ',
                  style: TextStyle(color: darkGrey, fontSize: 13),
                ),
                Icon(Icons.ev_station_rounded, size: 16, color: orange),
                Text(
                  ' $slots  ',
                  style: TextStyle(color: darkGrey, fontSize: 13),
                ),
                Icon(Icons.bolt_rounded, size: 16, color: orange),
                Text(
                  ' $power',
                  style: TextStyle(color: darkGrey, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              address,
              style: TextStyle(fontSize: 12, color: darkGrey),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                minimumSize: const Size(double.infinity, 38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onPressed: () {},
              child: const Text('Book Now'),
            ),
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
}
