// lib/features/home/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:eco_ev_app/features/home/screens/home_screen.dart';
import 'package:eco_ev_app/features/station/screens/stations_screen.dart';
import 'package:eco_ev_app/features/booking/screens/booking_screen.dart';
import 'package:eco_ev_app/features/profile/screens/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    StationsScreen(),
    BookingScreen(),
    // ❌ REMOVE ProfileScreen from tab views
  ];

  void _onItemTapped(int index) {
    if (index == 3) {
      _onProfileIconTapped(); // ✅ Handle Profile separately
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  void _onProfileIconTapped() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
        fullscreenDialog: true, // ✅ Hides bottom nav bar
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex > 2 ? 0 : _selectedIndex, // prevents out-of-range
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF138808),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.ev_station), label: "Stations"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Booking"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"), // ✅ still shown
        ],
      ),
    );
  }
}
