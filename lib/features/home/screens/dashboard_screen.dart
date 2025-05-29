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

  @override
  Widget build(BuildContext context) {
    // Each tab gets its own WillPopScope
    List<Widget> _screens = [
      HomeScreen(),
      WillPopScope(
        onWillPop: () async {
          setState(() {
            _selectedIndex = 0; // Go Home on back
          });
          return false; // Prevent default pop
        },
        child: StationsScreen(),
      ),
      WillPopScope(
        onWillPop: () async {
          setState(() {
            _selectedIndex = 0;
          });
          return false;
        },
        child: BookingScreen(),
      ),
      // ProfileScreen is a pushed route, handled separately
    ];

    void _onItemTapped(int index) {
      if (index == 3) {
        // Profile opened as a dialog, catch its pop there
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProfileScreenWithBackToHome(
              onBackToHome: () {
                setState(() => _selectedIndex = 0);
              },
            ),
            fullscreenDialog: true,
          ),
        );
      } else {
        setState(() => _selectedIndex = index);
      }
    }

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex > 2 ? 0 : _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF138808),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.ev_station), label: "Stations"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Booking"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// Use this wrapper to ensure back from profile returns to Home
class ProfileScreenWithBackToHome extends StatelessWidget {
  final VoidCallback onBackToHome;

  const ProfileScreenWithBackToHome({Key? key, required this.onBackToHome}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        onBackToHome();
        Navigator.of(context).pop();
        return false;
      },
      child: const ProfileScreen(),
    );
  }
}
