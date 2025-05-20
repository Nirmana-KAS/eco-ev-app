import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/otp_verification_screen.dart'; // Add this import
import 'screens/create_new_password_screen.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const EcoEvApp());
}

class EcoEvApp extends StatelessWidget {
  const EcoEvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ECO EV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primarySwatch: Colors.blue,
        // Add any other theme customizations here
      ),
      initialRoute: '/', // Splash first
      routes: {
        '/': (context) => SplashScreen(),
        '/welcome': (context) => WelcomeScreen(),
        '/sign-in': (context) => SignInScreen(),
        '/sign-up': (context) => SignUpScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/otp-verification': (context) => const OtpVerificationScreen(), // <-- Add this line
        '/create-new-password': (context) => CreateNewPasswordScreen(), // <-- Add this line
        // ...other routes
      },
    );
  }
}