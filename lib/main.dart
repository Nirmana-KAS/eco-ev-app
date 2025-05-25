import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eco_ev_app/data/services/auth_service.dart';
import 'package:eco_ev_app/data/services/notification_service.dart';
import 'package:eco_ev_app/app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init();
  runApp(const EcoEvEntry());
}

class EcoEvEntry extends StatefulWidget {
  const EcoEvEntry({super.key});

  @override
  State<EcoEvEntry> createState() => _EcoEvEntryState();
}

class _EcoEvEntryState extends State<EcoEvEntry> {
  @override
  void initState() {
    super.initState();
    _checkForEmailLink();
  }

  void _checkForEmailLink() async {
    final PendingDynamicLinkData? data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri? deepLink = data?.link;
    if (deepLink != null) {
      final prefs = await SharedPreferences.getInstance();
      final String? email = prefs.getString('emailForSignIn');
      if (email != null) {
        final error = await AuthService.signInWithEmailLink(
          email,
          deepLink.toString(),
        );
        if (error == null) {
          if (mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home', (route) => false);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(error)));
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Email not found, please try again.")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const EcoEvRoot(); // The main app with routing/auth gate
  }
}

class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await NotificationService.showNotification(
          'Your Title',
          'Your body message',
        );
      },
      child: const Text('Show Notification'),
    );
  }
}
