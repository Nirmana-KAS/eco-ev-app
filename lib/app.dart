import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/auth/screens/sign_in_screen.dart';
import 'features/auth/screens/sign_up_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/otp_verification_screen.dart';
import 'features/auth/screens/create_new_password_screen.dart';
import 'features/auth/screens/password_changed_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/map/screens/map_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/admin/screens/add_station_screen.dart';
import 'features/admin/screens/edit_station_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/about/screens/about_screen.dart';
import 'features/feedback/screens/feedback_screen.dart';
import 'features/booking/screens/booking_history_screen.dart';
import 'features/notifications/screens/notification_screen.dart';

// Theme setup
final ThemeData ecoEvTheme = ThemeData(
  primarySwatch: Colors.green,
  visualDensity: VisualDensity.adaptivePlatformDensity,
);

class EcoEvRoot extends StatelessWidget {
  const EcoEvRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ECO EV',
      debugShowCheckedModeBanner: false,
      theme: ecoEvTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/welcome': (context) => const WelcomeScreen(),
        '/sign-in': (context) => const SignInScreen(),
        '/sign-up': (context) => const SignUpScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/otp-verification': (context) => const OtpVerificationScreen(),
        '/create-new-password': (context) => const CreateNewPasswordScreen(),
        '/password-changed': (context) => const PasswordChangedScreen(),
        '/home': (context) => const HomeScreen(),
        '/map': (context) => const MapScreen(),
        '/admin': (context) => const AdminDashboardScreen(),
        '/add-station': (context) => const AddStationScreen(),
        '/edit-station': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return EditStationScreen(stationId: args);
        },
        '/profile': (context) => const ProfileScreen(),
        '/about': (context) => const AboutScreen(),
        '/feedback': (context) => const FeedbackScreen(),
        '/booking-history': (context) => const BookingHistoryScreen(),
        '/notifications': (context) => const NotificationScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const WelcomeScreen();
      },
    );
  }
}
